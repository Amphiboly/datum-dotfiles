#!/usr/bin/env bash
# ~/Projects/datum-config/mksecrets.sh
set -e

#1 Force script to execute from its own directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "===================================================="
echo "🔐 Refreshing and Encrypting Production Secrets..."
echo "===================================================="

#2 Look for staging file in directory above
if [ -f "../secrets.dec.yaml" ]; then
    # Atomically refresh the working staging file
    cp ../secrets.dec.yaml secrets.yaml
    
    # 3. Fire the encryption wrapper cleanly targeting the proper cache channel [a]
    nix-shell \
      --extra-experimental-features flakes \
      --option substituters "https://cache.nixos.org" \
      -p sops \
      --run "sops -e -i secrets.yaml"
      
    echo "✓ secrets.yaml successfully updated, encrypted, and locked."
else
    echo "❌ Error: secrets.dec.yaml unencrypted staging file not found in parent directory."
    exit 1
fi
