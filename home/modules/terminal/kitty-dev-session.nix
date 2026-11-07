# home/modules/terminal/kitty-dev-session.nix
#
# A kitty session for working on a project: one OS window in the Tall layout,
# vim full-height on the left, a build shell full-height on the right, and a
# spare shell docked as a strip along the bottom of the tab. Run `kdev` from
# the project directory. The session has no `cd`, so its windows start in the
# directory kitty was launched from; `vim .` opens it in NERDTree (which takes
# over netrw's directory buffers). `--hold` keeps the pane when vim quits, at
# a shell prompt; without it the pane closes and the build shell takes its
# full-height slot.
#
# The spare shell is a tab-dock (kitty 0.50+), 10 rows high and the full
# width of the tab. Docks sit outside the layout: next_window and
# move_window skip it, so window cycling only moves between vim and the
# build shell, and windows opened later in the tab join Tall above it
# without disturbing it. Click it to focus it. A tab-dock closes when the
# last non-docked window in the tab closes. It is a tab-dock rather than a
# window-dock on vim because a window-dock attaches to the active window,
# and which window that is while a session loads isn't specified.
#
# The dock gets SKIP_FASTFETCH=1, which rik's zsh (zsh-rik.nix) checks to
# skip its startup fastfetch: the logo doesn't fit in 10 rows, and the build
# shell already shows it. A `clear` can't do this, since fastfetch runs
# during zsh's startup, after any command the session could pass. In a shell
# that doesn't check the variable it does nothing.
#
# Tall's default 50:50 split gives vim about 123 columns when the kitty
# window is full width, about 82 at 2/3 width. To change it, add e.g.
# `enabled_layouts tall:bias=45,*` above the `layout` line (the `,*` keeps
# kitty's other layouts available in the tab).
{config, ...}: let
  session = "kitty/sessions/dev.kitty-session";
in {
  xdg.configFile.${session}.text = ''
    layout tall
    launch --hold vim .
    focus
    launch
    launch --type=tab-dock --dock-edge=bottom --dock-size=10 --env SKIP_FASTFETCH=1
  '';

  programs.zsh.shellAliases.kdev = "kitty --detach --session ${config.xdg.configHome}/${session}";
}
