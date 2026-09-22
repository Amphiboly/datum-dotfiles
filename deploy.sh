#!/usr/bin/env bash
# File: deploy.sh
# 2026-09-22: Removed the nostrum rsync mirror step -- Syncthing now keeps
#   ~/Projects (this repo included) current on nostrum on its own.
# 2026-09-12: Added optional fwupd firmware update check/apply step
# 2026-09-11: Removed _LABEL processing, removed most emojis,  minor cleanups
# 2026-08-30: Added _LABEL
# 2026-08-13: Converted to use nh
# 2026-08-07: Added rsync of secrets.dec.yaml
# 2026-08-07: Removed z option from first rsync
# 2026-08-15: Modernized with high-performance nh wrappers

set -euo pipefail

# Pause at the end is only useful for invokers whose terminal/panel would
# otherwise vanish before the output can be read (e.g. the noctalia
# nix-monitor widget's update_command). Interactive runs from an
# already-open shell don't need it, so it's opt-in via --pause.
PAUSE=0
[[ "${1:-}" == "--pause" ]] && PAUSE=1

echo "NixOS Workstation Deployment Engine Triggered..."
echo "=================================================="

# =========================================================================
# 1. Update Flake Inputs
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
# 2. Dry-Run Environment Mapping
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
# 3. Switch Live System Generations Natively via nh
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
# 4. Firmware Update Check (fwupd/LVFS)
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
# 5. Storage Profile Management
# =========================================================================
echo -e "\nSTORAGE CLEANUP SUITE"
echo "--------------------------------------------------"
read -rp "Purge obsolete configurations? (y/N): " clean_old </dev/tty
if [[ "$clean_old" =~ ^[Yy]$ ]]; then
    echo "Garbage collecting loose profiles and historical links..."
    nh clean all --keep 5
fi

echo -e "\nAll systems fully deployed and verified operational!"
echo    " Remember to commit and push the changes!"
if [[ "$PAUSE" -eq 1 ]]; then
    read -p "Press [Enter] to continue..." </dev/tty
fi
