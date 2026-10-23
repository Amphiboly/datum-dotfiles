# home/modules/terminal/kitty-dev-session.nix
#
# A kitty session for working on a project: one OS window in the Tall layout,
# helix full-height on the left, a build shell over a spare shell on the
# right. Run `kdev` from the project directory. The session has no `cd`, so
# its windows start in the directory kitty was launched from; `hx .` opens
# helix's file picker on it.
#
# bias=45 gives helix 45% of the window: about 123 columns when the kitty
# window is full width, about 82 at 2/3 width. The `,*` keeps kitty's other
# layouts available in the tab.
{config, ...}: let
  session = "kitty/sessions/dev.kitty-session";
in {
  xdg.configFile.${session}.text = ''
    enabled_layouts tall:bias=45,*
    layout tall
    launch hx .
    focus
    launch
    launch
  '';

  programs.zsh.shellAliases.kdev = "kitty --detach --session ${config.xdg.configHome}/${session}";
}
