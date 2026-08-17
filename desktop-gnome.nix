# ~/Projects/datum-config/desktop-gnome.nix
{pkgs, ...}: {
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  # Tell Nix to fetch GNOME packages straight from the official source
  nix.settings.substituters = [
    "https://cache.nixos.org"
  ];

  environment.systemPackages = with pkgs; [
    gnome-tweaks
  ];
}
