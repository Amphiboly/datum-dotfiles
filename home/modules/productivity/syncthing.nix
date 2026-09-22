# home/modules/productivity/syncthing.nix
#
# Enables the per-user Syncthing daemon and its web GUI (loopback-only by
# default). Device/folder wiring is personal, not shared shape -- see
# syncthing-rik.nix.
_: {
  services.syncthing.enable = true;
}
