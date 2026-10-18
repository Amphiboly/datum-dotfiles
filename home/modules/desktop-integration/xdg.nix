# home/modules/desktop-integration/xdg.nix
_: {
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain" = ["Helix.desktop"];
        "text/markdown" = ["Helix.desktop"];
        "application/x-shellscript" = ["Helix.desktop"];
      };
    };
    terminal-exec = {
      enable = true;
      settings.default = ["kitty.desktop"]; # Swift transition to Kitty
    };
    desktopEntries.yazi = {
      name = "Yazi";
      exec = "kitty -- yazi %u";
      terminal = false;
      icon = "yazi";
      categories = ["System" "FileTransfer"];
    };
  };
}
