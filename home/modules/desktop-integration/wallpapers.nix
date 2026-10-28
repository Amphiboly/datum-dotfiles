# home/modules/desktop-integration/wallpapers.nix
#
# The shared wallpaper set (assets/wallpaper/) in ~/Pictures/wallpapers for
# every user who imports this -- which is where each user's noctalia.toml
# points `[wallpaper] directory`. Noctalia only descends into subfolders for
# its slideshow automation, so the images land flat in that folder rather
# than in a subfolder of it.
#
# `recursive = true` links each file individually instead of making the
# whole folder one read-only store symlink, so users can still drop their
# own images in next to these. Adding a file to assets/wallpaper/ is all it
# takes to ship it (git add it first; flakes only see tracked files).
#
# COSMIC gets the same set system-wide from modules/nixos/desktop/wallpapers.nix.
# Both copy the folder in as plain `${path}`, so it is one store path. That
# is why `source` is an interpolated string, not a bare path: Home Manager
# copies a bare path again under its own "hm_" name, and these images would
# then sit in the store twice.
_: {
  home.file."Pictures/wallpapers" = {
    source = "${../../../assets/wallpaper}";
    recursive = true;
  };
}
