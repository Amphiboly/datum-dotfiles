# modules/nixos/desktop/wallpapers.nix
#
# The shared wallpaper set (assets/wallpaper/) system-wide, at
# /run/current-system/sw/share/backgrounds/datum, for every user and
# whichever user Home Manager config they have. COSMIC's wallpaper picker
# was what read it (it lists share/backgrounds/ in the XDG data dirs);
# since COSMIC went on 2026-11-03 nothing does. Kept as a candidate
# background for noctalia-greeter; drop it if that ends up not using it.
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

  # The COSMIC module used to link this too.
  environment.pathsToLink = ["/share/backgrounds"];
}
