# modules/nixos/remote-desktop.nix
#
# System-wide install of the FreeRDP client binaries (sdl-freerdp is the one
# in use). The .rdp handler and per-user hotkeys live in home-manager — see
# home/modules/desktop-integration/sdl-freerdp{,-rik}.nix.
{pkgs, ...}: {
  environment.systemPackages = [pkgs.freerdp];
}
