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
#
# SSH sessions get a white background, so a remote shell can't be mistaken
# for a local one (Noctalia's wallpaper-derived palette is never white).
# The `ssh` alias (zsh-rik.nix) runs `kitty +kitten ssh`, which reads
# ssh.conf; its `color_scheme` applies ssh-light.conf for the length of the
# session and restores the window's colours afterwards. Settings before any
# `hostname` line apply to every host. `command ssh` bypasses the kitten,
# and with it the colours. Only text, cursor and selection colours in the
# scheme file are used. The palette is GitHub Light, chosen so all sixteen
# colours stay readable on white.
_: {
  programs.kitty.extraConfig = ''
    include themes/noctalia.conf
    include ${../../../assets/rik/kitty.conf}
  '';

  xdg.configFile."kitty/ssh.conf".text = ''
    color_scheme ssh-light.conf
  '';

  xdg.configFile."kitty/ssh-light.conf".text = ''
    foreground #24292f
    background #ffffff
    cursor #0969da
    cursor_text_color #ffffff
    selection_foreground #24292f
    selection_background #b6e3ff
    color0 #24292f
    color8 #57606a
    color1 #cf222e
    color9 #a40e26
    color2 #116329
    color10 #1a7f37
    color3 #4d2d00
    color11 #633c01
    color4 #0969da
    color12 #218bff
    color5 #8250df
    color13 #a475f9
    color6 #1b7c83
    color14 #3192aa
    color7 #6e7781
    color15 #8c959f
  '';
}
