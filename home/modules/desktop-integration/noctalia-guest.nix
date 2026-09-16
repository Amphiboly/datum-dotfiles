# home/modules/desktop-integration/noctalia-guest.nix
#
# guest's Noctalia settings, split out from the shared enable/package logic
# in noctalia.nix. Currently a copy of rik's baseline (see noctalia-rik.nix)
# with the wallpaper paths pointed at guest's own home directory -- rik's
# copy was hardcoded to /home/rik/..., which guest can't read. Edit
# assets/guest/noctalia.toml directly to diverge further.
_: {
  programs.noctalia.settings = ../../../assets/guest/noctalia.toml;
}
