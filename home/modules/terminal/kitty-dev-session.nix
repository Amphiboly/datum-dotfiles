# home/modules/terminal/kitty-dev-session.nix
#
# A kitty session for working on a project: one OS window in the Tall layout,
# vim full-height on the left, a build shell over a spare shell on the
# right. Run `kdev` from the project directory. The session has no `cd`, so
# its windows start in the directory kitty was launched from; `vim .` opens
# it in NERDTree (which takes over netrw's directory buffers). `--hold`
# keeps the pane when vim quits, at a shell prompt; without it the pane
# closes and the build shell takes its full-height slot.
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
    launch
  '';

  programs.zsh.shellAliases.kdev = "kitty --detach --session ${config.xdg.configHome}/${session}";
}
