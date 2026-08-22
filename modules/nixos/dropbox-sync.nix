# modules/nixos/dropbox-sync.nix
#
# System-wide install of the maestral binary. The actual sync daemon is
# inherently per-user (own account, own credentials) — see
# home/modules/productivity/maestral-service.nix for the per-user systemd
# unit that individual profiles opt into.
{pkgs, ...}: {
  environment.systemPackages = [pkgs.maestral];
}
