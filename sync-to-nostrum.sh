#!/usr/bin/env bash
# File: sync-to-nostrum.sh
set -euo pipefail

# Define your host Fedora laptop's current active network IP address
NOSTRUM_IP="192.168.5.58" 

echo "🚀 Syncing pristine NixOS configurations back to Fedora..."

# Mirrors your workspace text files while tightly filtering out volatile git tracking blocks
rsync -avz --delete \
  --exclude='.git/' \
  --exclude='result*' \
  --exclude='*.backup' \
  ./ "rik@${NOSTRUM_IP}:~/Projects/datum/datum-config/"

echo "✓ Synchronization complete! Repositories are in a perfect 1:1 state."
