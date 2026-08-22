# home-guest.nix
{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./home/modules/theme/fonts.nix
    ./home/modules/shell/zsh.nix
    ./home/modules/shell/zsh-guest.nix
    ./home/modules/terminal/kitty.nix
    ./home/modules/terminal/kitty-guest.nix
    ./home/modules/browsers/firefox.nix
  ];

  home.username = "guest";
  home.homeDirectory = "/home/guest";
  home.stateVersion = "26.05";

  home.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "nano";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = ["firefox.desktop"];
    };
  };

  programs.home-manager.enable = true;
}
