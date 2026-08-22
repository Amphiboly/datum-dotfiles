# modules/nixos/remote-desktop.nix
#
# System-wide install of the remote-desktop client binaries. Per-user mime
# associations (which files launch Remmina) stay in home-manager — see
# home.nix's services.remmina.
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [remmina freerdp];
}
