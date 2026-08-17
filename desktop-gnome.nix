# ~/Projects/datum-config/desktop-gnome.nix
{pkgs, ...}: {
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.enable = true;

  # Inject specialized GNOME styling utilities and extensions
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnomeExtensions.appindicator
  ];
}
