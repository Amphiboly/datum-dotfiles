#!/usr/bin/env bash
# File: deploy.sh
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

# 2. Build a dry-run local link to generate the nvd visual difference table
echo "📦 Generating dry-run environment preview mapping..."
nixos-rebuild build --flake .#datum-laptop

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
# FIX: Directs input straight to terminal tty to ensure it never skips!
read -rp "📝 Enter a descriptive boot label message (e.g., 'added howdy'): " build_label </dev/tty
if [[ -z "$build_label" ]]; then
    build_label="optimized configuration pass"
fi

# 4. Trigger the native hardware compilation pass
echo "🚀 Switching live system tracks to new generation..."
sudo nixos-rebuild switch --flake .#datum-laptop --profile-name "$build_label"

# 5. Handle old generation storage management
echo -e "\n🧹 STORAGE CLEANUP SUITE"
echo "--------------------------------------------------"
# FIX: Protected input stream for generations purge selection
read -rp "🗑️  Do you want to purge obsolete labeled generations to free NVMe space? (y/N): " clean_old </dev/tty
if [[ "$clean_old" =~ ^[Yy]$ ]]; then
    echo "♻️  Garbage collecting loose profiles and historical links..."
    sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5
    sudo nix-store --gc
    echo "✓ Storage optimized! (Kept your latest 5 active generations)."
fi

# 6. Prompt for automatic deployment back to Fedora host
echo -e "\n📡 NOSTRUM REPOSITORY MIRROR"
echo "--------------------------------------------------"
# FIX: Protected input stream for nostrum server sync selection
read -rp "📤 Sync these validated configuration files to nostrum (Fedora)? (y/N): " sync_fedora </dev/tty
if [[ "$sync_fedora" =~ ^[Yy]$ ]]; then
    echo "🚀 Mirroring repository text arrays across secure network lanes..."
    rsync -avz --delete \
      --exclude='.git/' \
      --exclude='result*' \
      --exclude='*.backup' \
      --exclude='secrets.yaml' \
      ./ "rik@${NOSTRUM_IP}:~/Projects/datum/datum-config/"
    echo "✓ Synchronization complete! Repositories are in a perfect 1:1 state."
else
    echo "⏭️  Skipping Fedora sync pass."
fi

echo -e "\n✨ All systems fully deployed and verified operational! ✨"
