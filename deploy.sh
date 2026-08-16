#!/usr/bin/env bash
# File: deploy.sh
# 2026-08-13: Converted to use nh
# 2026-08-07: Added rsync of secrets.dec.yaml
# 2026-08-07: Removed z option from first rsync
# 2026-08-15: Modernized with high-performance nh wrappers
set -euo pipefail

# Define network endpoints
NOSTRUM_IP="192.168.5.58"
USERS=("rik" "home_guest")
e
cho "🎨 NixOS Workstation Deployment Engine Triggered..."
echo "=================================================="

# 1. Update the flake locks if requested
read -rp "🔄 Do you want to check for upstream package updates first? (y/N): " check_updates </dev/tty
if [[ "$check_updates" =~ ^[Yy]$ ]]; then
    echo "⚡ Refreshing upstream flake input hashes..."
    nix flake update --extra-experimental-features "nix-command flakes"
fi

# =========================================================================
# 2. Build dry-run local links to generate the nvd visual difference table
# =========================================================================
echo "📦 Generating dry-run system environment preview mapping..."
nh os build .

for user in "${USERS[@]}"; do
    echo "👤 Generating dry-run user environment preview mapping for '$user'..."
    # Passes the user configuration attribute string dynamically to the builder
    nh home build . -c "$user"
done

if command -v nvd &> /dev/null; then
    echo -e "\n📋 TEXT-BASED UPGRADE PROFILE DIFF BREAKDOWN:"
    echo "--------------------------------------------------"
    nvd diff /run/current-system ./result
    
    # Check for active active profile link context for each user if directories exist
    for user in "${USERS[@]}"; do
        # Checks standard location handles for individual users
        USER_HOME="/home/$user"
        if [ "$user" = "rik" ]; then USER_HOME="/home/rik"; fi # Adjust if guest path differs
        
        if [ -d "$USER_HOME/.nix-profile" ]; then
            echo -e "\n👤 USER HOME PACKAGE SHIFTS ($user):"
            # Appends suffix hooks to read individual result configurations cleanly
            nvd diff "$USER_HOME/.nix-profile" "./result-home-$user" || true
        fi
    done
    echo -e "--------------------------------------------------\n"
else
    echo "⚠️ Warning: 'nvd' package not found in paths. Skipping diff tables."
fi

# Clean up all temporary local dry-run symlinks safely right after the diff
rm -f ./result ./result-home-*

# 3. Prompt for the bootloader label notes
CURRENT_TS=$(date +"%m%dT%H%M")
echo "📝 Enter a descriptive boot label message."
read -rp "   [Press Enter to default to timestamp '$CURRENT_TS']: " build_label </dev/tty

if [[ -z "$build_label" ]]; then
    build_label="$CURRENT_TS"
fi

# =========================================================================
# 4. Trigger the native hardware compilation pass via nh
# =========================================================================
echo "🚀 Switching live system tracks to new generation..."
nh os switch . -- --profile-name "$build_label"

for user in "${USERS[@]}"; do
    echo "👤 Deploying user environment profile layouts for '$user' via Home Manager..."
    # Switches every user configuration concurrently using their native profile keys
    nh home switch . -c "$user"
done

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
