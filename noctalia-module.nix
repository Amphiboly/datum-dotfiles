# ~/Projects/datum-config/noctalia-module.nix
{
  config,
  pkgs,
  inputs,
  ...
}: {
  # 1. Install Noctalia v5 package system-wide
  environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # 2. Ensure core hardware communication lines are active for panel widgets
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
}
