#!/usr/bin/env bash
# ~/Projects/datum-config/mksecrets.sh
set -e # Terminate immediately if the encryption phase throws a validation error

echo "===================================================="
echo "🔐 Refreshing and Encrypting Production Secrets..."
echo "===================================================="

if [ -f "secrets.dec.yaml" ]; then
    # 1. Atomically refresh the working staging file
    cp secrets.dec.yaml secrets.yaml
    
    # 2. Fire the encryption wrapper cleanly targeting the proper cache channel [a]
    nix-shell \
      --option substituters "https://cache.nixos.org" \
      -p sops \
      --run "sops -e -i secrets.yaml"
      
    echo "✓ secrets.yaml successfully updated, encrypted, and locked."
else
    echo "❌ Error: secrets.dec.yaml unencrypted staging file not found in current path."
    exit 1
fi
