# home-guest.nix
_: {
  imports = [
    ./home/modules/unix-tools/claude-code.nix
    ./home/modules/theme/fonts.nix
    ./home/modules/shell/zsh.nix
    ./home/modules/shell/zsh-guest.nix
    ./home/modules/terminal/kitty.nix
    ./home/modules/terminal/kitty-guest.nix
    ./home/modules/browsers/firefox.nix
  ];

  home = {
    username = "guest";
    homeDirectory = "/home/guest";
    stateVersion = "26.05";
    sessionVariables = {
      EDITOR = "nano";
      VISUAL = "nano";
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
