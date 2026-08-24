# home/modules/terminal/kitty.nix
_: {
  programs.kitty = {
    settings = {
      confirm_os_window_close = 0;
      windw_padding_width = 4;
    };
  };
}
