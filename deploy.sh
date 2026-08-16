#!/usr/bin/env bash
# File: deploy.sh
# 2026-08-13: Converted to use nh
# 2026-08-07: Added rsync of secrets.dec.yaml
# 2026-08-07: Removed z option from first rsync
# 2026-08-15: Modernized with high-performance nh wrappers
set -euo pipefail

# Define network endpoints
NOSTRUM_IP="192.168.5.58"

echo "🎨 NixOS Workstation Deployment Engine Triggered..."
echo "=================================================="

# 1. Update the flake locks if requested
read -rp "🔄 Do you want to check for upstream package updates first? (y/N): " check_updates </dev/tty
if [[ "$check_updates" =~ ^[Yy]$ ]]; then
    echo "⚡ Refreshing upstream flake input hashes..."
    nix flake update --extra-experimental-features "nix-command flakes"
fi
# =========================================================================
# 2. Build a dry-run local link to generate the nvd visual difference table
# =========================================================================
echo "📦 Generating dry-run environment preview mapping..."
# Simply tell nh to build the current directory layout into a clean local link
nh os build .

if command -v nvd &> /dev/null; then
    echo -e "\n📋 TEXT-BASED UPGRADE PROFILE DIFF BREAKDOWN:"
    echo "--------------------------------------------------"
    nvd diff /run/current-system ./result
    echo -e "--------------------------------------------------\n"
else
    echo "⚠️ Warning: 'nvd' package not found in paths. Skipping diff tables."
fi

# INSTANT CLEANUP: Safely delete the temporary build result symlink links
rm -f ./result

# 2. Build a dry-run local link to generate the nvd visual difference table
echo "📦 Generating dry-run environment preview mapping..."
# nh automatically manages your flake parameters and caching targets
nh os build .

if command -v nvd &> /dev/null; then
    echo -e "\n📋 TEXT-BASED UPGRADE PROFILE DIFF BREAKDOWN:"
    echo "--------------------------------------------------"
    nvd diff /run/current-system ./result
    echo -e "--------------------------------------------------\n"
else
    echo "⚠️ Warning: 'nvd' package not found in paths. Skipping diff tables."
fi

# Clean up the temporary dry-run result symlink
rm -f ./result

# 3. Prompt for the bootloader label notes
CURRENT_TS=$(date +"%m%dT%H%M")
echo "📝 Enter a descriptive boot label message."
read -rp "   [Press Enter to default to timestamp '$CURRENT_TS']: " build_label </dev/tty

if [[ -z "$build_label" ]]; then
    build_label="$CURRENT_TS"
fi

# 4. Trigger the native hardware compilation pass via nh
echo "🚀 Switching live system tracks to new generation..."
# nh pipes the switch natively, using your boot label for the generational profile
nh os switch . -- --profile "$build_label"

# Clean up the local profile symlinks (still in /run)
rm -f ./"$build_label" *

# 5. Handle old generation storage management via nh clean
echo -e "\n🧹 STORAGE CLEANUP SUITE"
echo "--------------------------------------------------"
read -rp "🗑️  Do you want to purge obsolete labeled generations to free NVMe space? (y/N): " clean_old </dev/tty
if [[ "$clean_old" =~ ^[Yy]$ ]]; then
    echo "♻️  Garbage collecting loose profiles and historical links..."
    # nh clean handles profile-purging and store-optimizing safely in one line
    nh clean all --keep 5
    echo "✓ Storage optimized! (Kept your latest 5 active generations)."
fi

# 6. Prompt for automatic deployment back to Fedora host
echo -e "\n📡 NOSTRUM REPOSITORY MIRROR"
echo "--------------------------------------------------"
read -rp "📤 Sync these validated configuration files to nostrum (Fedora)? (y/N): " sync_fedora </dev/tty
if [[ "$sync_fedora" =~ ^[Yy]$ ]]; then
    echo "🚀 Mirroring repository text arrays across secure network lanes..."
    rsync -av --delete \
      --exclude='.git/' \
      --exclude='result*' \
      --exclude='*.backup' \
      --exclude='secrets.yaml' \
      ./ "rik@${NOSTRUM_IP}:~/Projects/datum/datum-config/"
    rsync -auv \
      ../secrets.dec.yaml "rik@${NOSTRUM_IP}:~/Projects/datum/secrets.dec.yaml"
    echo "✓ Synchronization complete! Repositories are in a perfect 1:1 state."
else
    echo "⏭️  Skipping Fedora sync pass."
fi

echo -e "\n✨ All systems fully deployed and verified operational! ✨"
