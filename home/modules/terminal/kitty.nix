# home/modules/terminal/kitty.nix
{config, ...}: {
  home.sessionVariables.TERMINAL = "kitty";

  programs.kitty = {
    enable = true;
    autoThemeFiles = {
      light = "ayu_light";
      dark = "Catppuccin-Mocha";
      noPreference = "Catppuccin-Mocha";
    };
    font = {
      name = config.theme.font.mono;
      size = config.theme.font.monoSize;
    };
    settings = {
      scrollback_lines = 10000;
      close_on_child_death = "yes";
      update_check_interval = 0; # Disables redundant background update checks
      background_opacity = "0.95";

      "wayland_enable_ime" = "no";

      # —————————————————————————————————————————————————————————————————————
      # ZELLIJ KEYBIND PASS-THROUGH OVERRIDES
      # —————————————————————————————————————————————————————————————————————
      "map ctrl+shift+t" = "no_op";
      "map ctrl+shift+w" = "no_op";
      "map ctrl+shift+enter" = "no_op";
    };
  };
}
