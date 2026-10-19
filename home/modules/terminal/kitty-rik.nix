# home/modules/terminal/kitty-rik.nix
#
# rik's kitty settings live in assets/rik/kitty.conf: kitty's full commented
# default config with rik's changes uncommented, kept whole so it can be
# diffed against a new release's defaults. It is pulled in with kitty's
# `include` rather than replacing kitty.conf, so Home Manager's generated
# parts (font from the theme module, auto themes below, shell integration)
# still apply. The include comes last, so settings in the file win.
#
# To try a setting before editing the asset (kitty.conf is a read-only store
# link): `kitty -o key=value`, or `kitty -c ~/.config/kitty/kitty.conf -c
# /path/to/trial.conf` for a batch of them.
_: {
  programs.kitty = {
    extraConfig = "include ${../../../assets/rik/kitty.conf}";
    autoThemeFiles = {
      light = "Tomorrow";
      dark = "Tomorrow_Night_Bright";
      noPreference = "Tomorrow_Night_Bright";
    };
  };
}
