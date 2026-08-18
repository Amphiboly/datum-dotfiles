# ~/Projects/datum-config/desktop-cosmic.nix
{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixos-cosmic.nixosModules.default
  ];

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # Enforce the double cache download path mapping
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://cosmic.cachix.org" # Correct, verified binary cache address!
  ];

  environment.systemPackages = with pkgs; [
    #   cosmic-ext-applet-audio-select
  ];
}
