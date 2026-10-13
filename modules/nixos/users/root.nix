# modules/nixos/users/root.nix
#
# No password is set here. This repo is public, so anything in it is a known
# password; until 2026-10-13 this file set `initialPassword = "nix"`.
# With mutableUsers (users/default.nix), removing it changes nothing on a
# running system: root keeps whatever `passwd` last set. On a reinstall, run
# nixos-install WITHOUT --no-root-passwd and it prompts for root's password;
# otherwise root starts locked, which leaves sudo from rik as the only way
# in, and no root login in the emergency shell.
_: {}
