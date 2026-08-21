# home-guest.nix
{
  config,
  pkgs,
  ...
}: {
  home.username = "guest";
  home.homeDirectory = "/home/guest";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    firefox
  ];

  home.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "nano";
  };

  programs.kitty = {
    enable = true;
    settings.enable_audio_bell = false;
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      ls = "ls --color=auto";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = ["firefox.desktop"];
    };
  };

  programs.home-manager.enable = true;
}
