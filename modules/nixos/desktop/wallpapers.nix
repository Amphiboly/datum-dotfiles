# modules/nixos/desktop/wallpapers.nix
#
# The shared wallpaper set (assets/wallpaper/) system-wide, at
# /run/current-system/sw/share/backgrounds/datum, for every user and
# whichever user Home Manager config they have. COSMIC's wallpaper picker
# lists what's under share/backgrounds/ in the XDG data dirs; that is how
# it already finds cosmic-wallpapers (share/backgrounds/cosmic).
#
# Noctalia doesn't look here: it reads one folder per user, filled by
# home/modules/desktop-integration/wallpapers.nix from the same assets.
{pkgs, ...}: {
  environment.systemPackages = [
    (pkgs.linkFarm "datum-wallpapers" [
      {
        name = "share/backgrounds/datum";
        path = ../../../assets/wallpaper;
      }
    ])
  ];

  # The COSMIC module already links this; stated here so this module stands
  # on its own if COSMIC ever goes.
  environment.pathsToLink = ["/share/backgrounds"];
}
