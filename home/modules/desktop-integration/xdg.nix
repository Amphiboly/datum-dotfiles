# home/modules/desktop-integration/xdg.nix
_: {
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain" = ["dev.zed.Zed.desktop"];
        "text/markdown" = ["dev.zed.Zed.desktop"];
        "application/x-shellscript" = ["dev.zed.Zed.desktop"];
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
