# home/modules/terminal/kitty-rik.nix
#
# rik's kitty settings live in assets/rik/kitty.conf: kitty's full commented
# default config with rik's changes uncommented, kept whole so it can be
# diffed against a new release's defaults. It is pulled in with kitty's
# `include` rather than replacing kitty.conf, so Home Manager's generated
# parts (font from the theme module, shell integration) still apply. The
# include comes last, so settings in the file win.
#
# Colours come from Noctalia: its built-in kitty template renders
# ~/.config/kitty/themes/noctalia.conf from the shell's palette (it follows
# Noctalia's light/dark `mode`), and the first include below loads it.
# Noctalia's own hook would add that include itself, but kitty.conf is a
# read-only store link, so it fails ("cannot touch kitty.conf") and the
# include lives here instead. Same failure means Noctalia can't signal
# running kittys: palette changes show up in new windows, or after
# ctrl+shift+f5 (reload config) in existing ones. No autoThemeFiles: kitty
# would switch to them on the OS light/dark change, over Noctalia's colours.
#
# To try a setting before editing the asset (kitty.conf is a read-only store
# link): `kitty -o key=value`, or `kitty -c ~/.config/kitty/kitty.conf -c
# /path/to/trial.conf` for a batch of them.
_: {
  programs.kitty.extraConfig = ''
    include themes/noctalia.conf
    include ${../../../assets/rik/kitty.conf}
  '';
}
