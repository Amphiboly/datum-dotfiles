#!/usr/bin/env bash
# mksecrets.sh (installed as `mksecrets` by home.nix)
#
# Encrypts the plaintext staging files into the repo:
#   ../secrets.dec/<name>.yaml  ->  secrets/<name>.yaml
# for every <name>.yaml in the staging directory, each under its own
# creation rule in .sops.yaml (sops refuses a file that has none). Today
# that's common.yaml and datum.yaml; a nostrum.yaml needs a rule first.
#
# The plaintext is read where it is, never copied into the repo, and each
# output is replaced only once its encryption has succeeded. Every run
# re-encrypts from scratch, so all ciphertext changes even where the
# plaintext didn't; nix still sees the same secrets.
#
# REPO defaults to rik's checkout. Set REPO=... for another one.
#
# sops comes from PATH if it's there; otherwise the script runs itself
# again inside `nix shell nixpkgs#sops`. That keeps sops (about 50 MiB)
# out of the installed closure for a command that runs now and then.
set -euo pipefail

if ! command -v sops >/dev/null; then
  # MKSECRETS_IN_NIX_SHELL stops a loop if the shell somehow lacks sops.
  [ -z "${MKSECRETS_IN_NIX_SHELL:-}" ] || {
    echo "mksecrets: still no sops inside nix shell" >&2
    exit 1
  }
  echo "mksecrets: sops not on PATH; running under nix shell nixpkgs#sops" >&2
  export MKSECRETS_IN_NIX_SHELL=1
  exec nix shell nixpkgs#sops -c bash "$0" "$@"
fi

REPO=${REPO:-$HOME/Projects/datum/datum-config}
STAGE=$(dirname "$REPO")/secrets.dec

die() {
  echo "mksecrets: $*" >&2
  exit 1
}

[ -d "$STAGE" ] || die "no staging directory $STAGE"
cd "$REPO"

shopt -s nullglob
sources=("$STAGE"/*.yaml)
[ ${#sources[@]} -gt 0 ] || die "nothing to encrypt in $STAGE"

mkdir -p secrets
tmp=""
trap 'rm -f "$tmp"' EXIT
for src in "${sources[@]}"; do
  name=$(basename "$src")
  out=secrets/$name
  # Same directory as the output, so the mv below is atomic.
  tmp=$(mktemp "secrets/.$name.XXXXXX")
  sops encrypt --filename-override "$out" --output "$tmp" "$src" \
    || die "encrypting $src failed; $out left as it was"
  mv "$tmp" "$out"
  tmp=""
  echo "encrypted $src -> $out"
done

# Encrypted files with no plaintext counterpart are probably left over.
for out in secrets/*.yaml; do
  [ -e "$STAGE/$(basename "$out")" ] \
    || echo "note: $out has no staging file in $STAGE; delete it if it's obsolete"
done
[ ! -e "$(dirname "$REPO")/secrets.dec.yaml" ] \
  || echo "note: $(dirname "$REPO")/secrets.dec.yaml is no longer used; the staging files are in $STAGE"
