# modules/nixos/session-daemons.nix
{...}: {
  # Optimization tier for smooth interactive window scaling
  services.system76-scheduler.enable = true;
  # Required user context tracking backend for modern greeters and multi-user configurations
  services.accounts-daemon.enable = true;
}
