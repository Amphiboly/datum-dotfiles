# home/modules/terminal/kitty-rik.nix
_: {
  programs.kitty = {
    settings = {
      confirm_os_window_close = 0;
      windw_padding_width = 4;
    };
    autoThemeFiles = {
      light = "Tomorrow";
      dark = "Tomorrow_Night_Bright";
      noPreference = "Tomorrow_Night_Bright";
    };
  };
}
