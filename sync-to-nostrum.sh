#!/usr/bin/env bash
# File: sync-to-nostrum.sh
# 2026-08-07: Added rsync of secrets.dec.yaml
# 2026-08-07: Removed z option from first rsync
set -euo pipefail

# Define your host Fedora laptop's current active network IP address
NOSTRUM_IP="192.168.5.58" 

echo "🚀 Syncing pristine NixOS configurations back to Fedora..."

# Mirrors your workspace text files while tightly filtering out volatile git tracking blocks
rsync -av --delete \
  --exclude='.git/' \
  --exclude='result*' \
  --exclude='*.backup' \
  ./ "rik@${NOSTRUM_IP}:~/Projects/datum/datum-config/"
rsync -auv \
  ../secrets.dec.yaml "rik@${NOSTRUM_IP}:~/Projects/datum/secrets.dec.yaml"  

echo "✓ Synchronization complete! Repositories are in a perfect 1:1 state."
