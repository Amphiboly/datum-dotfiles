# home/modules/media/cmus.nix
#
# cmus, the terminal music player (2026-11-09). Audio only; mpv stays
# the video player (mpv.nix).
#
# No theme is set on purpose: cmus's built-in default colour scheme uses
# the terminal's 16 ANSI colours, and kitty takes those from Noctalia,
# so cmus follows the palette without a template of its own. Setting
# programs.cmus.theme would pin it to fixed colours instead.
#
# No MIME associations either: cmus ships no desktop entry and doesn't
# play files given on its command line (that's cmus-remote's job, and
# only with cmus already running), so it can't be an xdg default.
_: {
  programs.cmus.enable = true;
}
