#!/usr/bin/env bash
# File: deploy.sh
# 2026-11-18: nh 4.5: optional activation preview (dry-activate) with a
#   switch/boot choice; nvd dropped in favour of nh's own build diff;
#   "dry-run" step renamed, since it's a real build.
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
# Set only when we update: a copy of flake.lock as it was before, so a failed
# dry run can put it back (step 2). Copying rather than `git checkout` keeps
# any lock change that was already in the working tree.
lock_backup=""
if [[ "$check_updates" =~ ^[Yy]$ ]]; then
    lock_backup=$(mktemp)
    trap 'rm -f "$lock_backup"' EXIT
    cp flake.lock "$lock_backup"
    echo "Refreshing upstream flake input hashes..."
    # nh 4.x dropped the standalone `flake` subcommand — input updates are now
    # a flag on `nh os build/switch` (-u/--update) rather than a separate
    # lock-file-only action, so we call plain `nix flake update` here instead.
    nix flake update
fi

# =========================================================================
# 2. Build and Diff
# =========================================================================
echo "Building the new system generation..."
# --keep-going: when one derivation fails, still build everything that
# doesn't depend on it, so those land in the store and the next run only
# redoes the broken part. The system itself still can't be built until the
# failure is fixed, so the script stops here either way.
# -o ./result: nh's default out-link is a temp dir. The preview in step 3
# and the rm after the switch both need this exact path, and it's the GC
# root for the build until the switch registers the generation.
# Not `nh os build --dry`: that only lists what would be built, and nothing
# after this step would have a ./result to work on.
#
# nh prints its package diff against the running system (dix) once the
# build finishes; the later steps pass --diff never so it isn't repeated.
#
# If it fails after an update, restore flake.lock, as the nightly upgrade
# does: otherwise the next deploy rebuilds the same broken inputs even when
# you answer "no" to updating. The update's successful builds stay in the
# store, so retrying the update later costs little.
if ! nh os build --keep-going -o ./result; then
    if [[ -n "$lock_backup" ]]; then
        cp "$lock_backup" flake.lock
        echo "Build failed; flake.lock restored to its pre-update state."
    fi
    exit 1
fi

# =========================================================================
# 3. Preview Activation (optional)
# =========================================================================
# dry-activate runs switch-to-configuration in dry-activate mode on the
# ./result just built (no re-evaluation): it lists the units a switch would
# stop, restart, reload and start, and changes nothing. Worth a look when a
# change touches mounts or filesystems. Under impermanence, switching to a
# config with a new .mount whose device or subvolume doesn't exist yet drops
# the running system into emergency mode (see CLAUDE.md); dry-activate won't
# check the device, but the new .mount shows up under "would start", and
# then boot is the safe choice.
mode=switch
read -rp "Preview activation before switching? (y/N): " preview </dev/tty
if [[ "$preview" =~ ^[Yy]$ ]]; then
    nh os dry-activate --diff never ./result
    read -rp "[s]witch now, [b]oot (activate at next reboot), or [a]bort? (S/b/a): " choice </dev/tty
    case "$choice" in
        [Bb]*) mode=boot ;;
        [Aa]*) echo "Aborted; nothing activated. ./result is kept as a GC root."
               exit 0 ;;
    esac
fi

# =========================================================================
# 4. Switch (or Stage for Boot) via nh
# =========================================================================
# Deliberately no --continue-on-activation-failure: a failed activation
# should stop here, not leave a half-activated generation as the boot
# default.
echo "Activating the new generation ($mode)..."
# This single command safely compiles your system and both user profiles simultaneously!
nh os "$mode" --diff never .
if [[ "$mode" == boot ]]; then
    echo "New generation is the boot default; it takes effect after a reboot."
fi

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
        # fwupdmgr exits 2 for "nothing to do" (metadata already fresh, no
        # updates), distinct from 1 for a real error. The `|| rc=$?` form
        # also keeps either from tripping set -e.
        rc=0
        fwupdmgr refresh || rc=$?
        if (( rc == 1 )); then
            echo "Metadata refresh failed (offline?) — continuing with cached data."
        fi

        rc=0
        fwupdmgr get-updates || rc=$?
        if (( rc == 0 )); then
            read -rp "Apply available firmware updates now? (y/N): " apply_firmware </dev/tty
            if [[ "$apply_firmware" =~ ^[Yy]$ ]]; then
                echo "Applying firmware updates. Some devices (notably UEFI/BIOS) will require a reboot to complete."
                fwupdmgr update
            fi
        elif (( rc == 1 )); then
            echo "Checking for firmware updates failed — see the error above."
        fi
        # rc == 2: fwupdmgr has already printed "No updates available".
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

echo -e "\nAll systems fully deployed and verified operational!"
echo    " Remember to commit and push the changes!"
if [[ "$PAUSE" -eq 1 ]]; then
    read -p "Press [Enter] to continue..." </dev/tty
fi
