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
# `source` is an interpolated string, not a bare path, from when the same
# set was also system-wide for COSMIC's wallpaper picker (until
# 2026-11-03): both copied the folder in as plain `${path}`, one store
# path, where a bare path would have made Home Manager copy it again under
# its own "hm_" name. With one user of it left, either form stores it once.
# The login screen gets its background from Noctalia's greeter sync
# instead (modules/nixos/desktop/noctalia-greeter.nix).
_: {
  home.file."Pictures/wallpapers" = {
    source = "${../../../assets/wallpaper}";
    recursive = true;
  };
}
