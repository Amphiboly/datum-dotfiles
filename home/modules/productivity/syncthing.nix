# home/modules/productivity/syncthing.nix
#
# Enables the per-user Syncthing daemon and its web GUI (loopback-only by
# default). Device/folder wiring is personal, not shared shape -- see
# syncthing-rik.nix.
#
# guiCredentials is deliberately unset: the GUI only binds 127.0.0.1:8384,
# datum is single-user, and nothing off-box can reach it, so a login is
# just another secret to rotate for no real gain here. If that changes,
# wire services.syncthing.guiCredentials.passwordFile to a sops secret,
# same pattern as the CIFS credentials in modules/nixos/filesystems.nix.
_: {
  services.syncthing.enable = true;
}
