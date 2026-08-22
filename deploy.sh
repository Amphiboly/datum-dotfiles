#!/usr/bin/env bash
# File: deploy.sh
# 2026-08-13: Converted to use nh
# 2026-08-07: Added rsync of secrets.dec.yaml
# 2026-08-07: Removed z option from first rsync
# 2026-08-15: Modernized with high-performance nh wrappers

set -euo pipefail

# =========================================================================
# 1. Establish structural network endpoints
# =========================================================================
NOSTRUM_IP="192.168.5.58"

echo "🎨 NixOS Workstation Deployment Engine Triggered..."
echo "=================================================="

# =========================================================================
# 2. Update Flake Inputs
# =========================================================================
read -rp "🔄 Check for upstream package updates? (y/N): " check_updates </dev/tty
if [[ "$check_updates" =~ ^[Yy]$ ]]; then
    echo "⚡ Refreshing upstream flake input hashes..."
    # nh 4.x dropped the standalone `flake` subcommand — input updates are now
    # a flag on `nh os build/switch` (-u/--update) rather than a separate
    # lock-file-only action, so we call plain `nix flake update` here instead.
    nix flake update
fi

# =========================================================================
# 3. Dry-Run Environment Mapping
# =========================================================================
echo "📦 Generating dry-run system environment preview mapping..."
nh os build

if command -v nvd &> /dev/null; then
    echo -e "\n📋 TEXT-BASED UPGRADE PROFILE DIFF BREAKDOWN:"
    echo "--------------------------------------------------"
    nvd diff /run/current-system ./result
    echo -e "--------------------------------------------------\n"
else
    echo "⚠️ Warning: 'nvd' package not found in paths. Skipping diff tables."
fi

# Clean up local dry-run symlink cleanly right after the comparison pass
rm -f ./result

# =========================================================================
# 4. Compute Automatic Chronological Datetime Timestamp
# =========================================================================
#CURRENT_TS=$(date +"%m%dT%H%M")
#echo "📝 Enter a descriptive boot label message."
#read -rp "   [Press Enter to default to timestamp '$CURRENT_TS']: " build_label </dev/tty
#
#if [[ -z "$build_label" ]]; then
#    build_label="$CURRENT_TS"
#fi

# =========================================================================
# 5. Switch Live System Generations Natively via nh
# =========================================================================
echo "🚀 Switching live system tracks to new generation..."
# This single command safely compiles your system and both user profiles simultaneously!
nh os switch . # -- --profile "$build_label"

# =========================================================================
# 6. Storage Profile Management
# =========================================================================
echo -e "\n🧹 STORAGE CLEANUP SUITE"
echo "--------------------------------------------------"
read -rp "🗑️  Purge obsolete configurations? (y/N): " clean_old </dev/tty
if [[ "$clean_old" =~ ^[Yy]$ ]]; then
    echo "♻️  Garbage collecting loose profiles and historical links..."
    nh clean all --keep 5
fi

# =========================================================================
# 7. Remote Repository Mirror Array
# =========================================================================
echo -e "\n📡 NOSTRUM REPOSITORY MIRROR"
echo "--------------------------------------------------"
read -rp "📤 Sync validated files to nostrum (Fedora)? (y/N): " sync_fedora </dev/tty
if [[ "$sync_fedora" =~ ^[Yy]$ ]]; then
    echo "🚀 Mirroring repository across secure network lanes..."
    rsync -av --delete --exclude='.git/' --exclude='result*' --exclude='*.backup' --exclude='secrets.yaml' ./ "rik@${NOSTRUM_IP}:~/Projects/datum/datum-config/"
    rsync -auv ../secrets.dec.yaml "rik@${NOSTRUM_IP}:~/Projects/datum/secrets.dec.yaml"
    echo "✓ Synchronization complete!"
else
    echo "⏭️  Skipping Fedora sync pass."
fi

echo -e "\n✨ All systems fully deployed and verified operational! ✨"
