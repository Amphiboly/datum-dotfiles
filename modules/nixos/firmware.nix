# modules/nixos/firmware.nix
#
# UEFI/BIOS and device firmware updates via fwupd (LVFS). Ships fwupdmgr for
# CLI use; no GUI front-end is wired in.
#
# Updates still require a manual `fwupdmgr refresh && fwupdmgr update` (or
# GNOME Firmware / Plasma Discover's firmware page, if installed) — this
# module only enables the daemon, it does not apply updates automatically.
_: {
  services.fwupd.enable = true;
}
