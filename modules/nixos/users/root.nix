# modules/nixos/users/root.nix
#
# root's password is a sops hash (secrets.nix), not a literal: this repo is
# public, so anything written here is a known password. (Until 2026-10-13
# this file set `initialPassword = "nix"`.) It gives a second way in that
# doesn't depend on rik: root at a console, and in stage 2's emergency
# shell. The initrd's emergency shell is locked regardless.
#
# Applied at every activation (immutable users, users/default.nix, which
# has the procedure for changing it; use root-password-hash). On a
# reinstall, run nixos-install with --no-root-passwd: the sops hash sets it.
{config, ...}: {
  users.users.root.hashedPasswordFile = config.sops.secrets."root-password-hash".path;
}
