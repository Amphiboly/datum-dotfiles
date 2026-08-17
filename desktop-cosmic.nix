# ~/Projects/datum-config/desktop-cosmic.nix
{pkgs, ...}: {
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # Inject specific COSMIC components
  environment.systemPackages = with pkgs; [
    cosmic-ext-applet-audio-select
  ];
}
