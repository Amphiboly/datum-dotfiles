# home/modules/terminal/kitty-guest.nix
_: {
  programs.kitty = {
    settings.enable_audio_bell = false;
    autoThemeFiles = {
      light = "ayu_light";
      dark = "Catppuccin-Mocha";
      noPreference = "Catppuccin-Mocha";
    };
  };
}
