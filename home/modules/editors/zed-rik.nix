# home/modules/editors/zed-rik.nix
#
# Preferences: theme/fonts and the $VISUAL default. Enablement lives in
# zed.nix.
{config, ...}: {
  home.sessionVariables.VISUAL = "zed";

  programs.zed-editor.userSettings = {
    theme = "Night Owl";
    ui_font_size = config.theme.font.uiSize;
    buffer_font_family = config.theme.font.mono;
    buffer_font_size = config.theme.font.monoSize;
  };
}
