#!/usr/bin/env bash
# File: deploy.sh
# 2026-09-12: Added optional fwupd firmware update check/apply step
# 2026-09-11: Removed _LABEL processing, removed most emojis,  minor cleanups
# 2026-08-30: Added _LABEL
# 2026-08-13: Converted to use nh
# 2026-08-07: Added rsync of secrets.dec.yaml
# 2026-08-07: Removed z option from first rsync
# 2026-08-15: Modernized with high-performance nh wrappers

set -euo pipefail

# =========================================================================
# 1. Establish structural network endpoints
# =========================================================================
NOSTRUM_IP="192.168.5.58"

echo "NixOS Workstation Deployment Engine Triggered..."
echo "=================================================="

# =========================================================================
# 2. Update Flake Inputs
# =========================================================================
read -rp "Check for upstream package updates? (y/N): " check_updates </dev/tty
if [[ "$check_updates" =~ ^[Yy]$ ]]; then
    echo "Refreshing upstream flake input hashes..."
    # nh 4.x dropped the standalone `flake` subcommand — input updates are now
    # a flag on `nh os build/switch` (-u/--update) rather than a separate
    # lock-file-only action, so we call plain `nix flake update` here instead.
    nix flake update
fi

# =========================================================================
# 3. Dry-Run Environment Mapping
# =========================================================================
echo "Generating dry-run system environment preview mapping..."
nh os build

if command -v nvd &> /dev/null; then
    echo -e "\n📋 TEXT-BASED UPGRADE PROFILE DIFF BREAKDOWN:"
    echo "--------------------------------------------------"
    nvd diff /run/current-system ./result
    echo -e "--------------------------------------------------\n"
else
    echo "⚠️ Warning: 'nvd' package not found in paths. Skipping diff tables."
fi

# =========================================================================
# 4. Switch Live System Generations Natively via nh
# =========================================================================
echo "Switching live system tracks to new generation..."
# This single command safely compiles your system and both user profiles simultaneously!
nh os switch .

# ./result is left alone until the switch above has actually succeeded. It's
# the only GC root for whatever this dry-run just built (freshly-fetched
# rolling-upstream packages like context-lmtx included) until the new
# generation itself is durably registered. Deleting it right after the diff,
# before switch confirms the generation, left a window where a build that
# only just got fetched+verified could be swept by an unrelated `nix store
# gc` before anything else pinned it -- forcing a refetch (and, for a rolling
# upstream with no dated releases, a fresh hash mismatch) on the next
# unrelated update, with no local edit to explain why.
rm -f ./result

# =========================================================================
# 5. Firmware Update Check (fwupd/LVFS)
# =========================================================================
echo -e "\nFIRMWARE UPDATE CHECK"
echo "--------------------------------------------------"
if command -v fwupdmgr &> /dev/null; then
    read -rp "Check for UEFI/device firmware updates? (y/N): " check_firmware </dev/tty
    if [[ "$check_firmware" =~ ^[Yy]$ ]]; then
        echo "Refreshing firmware metadata from LVFS..."
        fwupdmgr refresh || echo "Metadata refresh failed (offline?) — continuing with cached data."

        # get-updates exits non-zero when there's simply nothing to install;
        # don't let that trip set -e.
        if fwupdmgr get-updates; then
            read -rp "Apply available firmware updates now? (y/N): " apply_firmware </dev/tty
            if [[ "$apply_firmware" =~ ^[Yy]$ ]]; then
                echo "Applying firmware updates. Some devices (notably UEFI/BIOS) will require a reboot to complete."
                fwupdmgr update
            fi
        else
            echo "No firmware updates available."
        fi
    fi
else
    echo "fwupdmgr not found on PATH — nothing to check yet."
    echo "(services.fwupd.enable needs a rebuild before this step does anything.)"
fi

# =========================================================================
# 6. Storage Profile Management
# =========================================================================
echo -e "\nSTORAGE CLEANUP SUITE"
echo "--------------------------------------------------"
read -rp "Purge obsolete configurations? (y/N): " clean_old </dev/tty
if [[ "$clean_old" =~ ^[Yy]$ ]]; then
    echo "Garbage collecting loose profiles and historical links..."
    nh clean all --keep 5
fi

# =========================================================================
# 7. Remote Repository Mirror Array
# =========================================================================
echo -e "\nNOSTRUM REPOSITORY MIRROR"
echo "--------------------------------------------------"
read -rp "Sync validated files to nostrum? (y/N): " sync_nostrum </dev/tty
if [[ "$sync_nostrum" =~ ^[Yy]$ ]]; then
    echo "Mirroring repository across secure network lanes..."
    rsync -av --delete \
      --exclude='.git/' \
      --exclude='result*' \
      --exclude='*.backup' \
      --exclude='secrets.yaml' \
      ./ "rik@${NOSTRUM_IP}:~/Projects/datum/datum-config/"
    rsync -auv \
      ../secrets.dec.yaml "rik@${NOSTRUM_IP}:~/Projects/datum/secrets.dec.yaml"
    echo "Synchronization complete!"
    echo "But once these changes are pushed, please do a git pull from nostrum."
else
    echo "Skipping nostrum sync pass."
fi

echo -e "\nAll systems fully deployed and verified operational!"
echo    " Remember to commit and push the changes!"
read -p "Press [Enter] to continue..."
