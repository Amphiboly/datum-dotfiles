# home/modules/desktop-integration/xdg.nix
_: {
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain" = ["vim.desktop"];
        "text/markdown" = ["vim.desktop"];
        "application/x-shellscript" = ["vim.desktop"];
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
