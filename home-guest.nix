# home-guest.nix
_: {
  imports = [
    ./home/modules/unix-tools/claude-code.nix
    #   ./home/modules/unix-tools/claude-code-guest.nix # optional, non-existant
    ./home/modules/theme/fonts.nix
    ./home/modules/shell/zsh.nix
    ./home/modules/shell/zsh-guest.nix
    ./home/modules/terminal/kitty.nix
    ./home/modules/terminal/kitty-guest.nix
    ./home/modules/browsers/firefox.nix
    ./home/modules/desktop-integration/wallpapers.nix
    ./home/modules/desktop-integration/noctalia.nix
    ./home/modules/desktop-integration/noctalia-guest.nix
    ./home/modules/desktop-integration/umbriel-guest.nix
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
