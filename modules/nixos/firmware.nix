# modules/nixos/firmware.nix
#
# UEFI/BIOS and device firmware updates via fwupd (LVFS). Ships fwupdmgr for
# CLI use; there's no GUI front-end wired in since COSMIC doesn't have a
# Software Center with fwupd integration yet.
#
# Updates still require a manual `fwupdmgr refresh && fwupdmgr update` (or
# GNOME Firmware / Plasma Discover's firmware page, if installed) — this
# module only enables the daemon, it does not apply updates automatically.
{...}: {
  services.fwupd.enable = true;
}
