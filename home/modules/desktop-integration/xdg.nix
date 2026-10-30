# home/modules/desktop-integration/xdg.nix
_: {
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain" = ["vim.desktop"];
        "text/markdown" = ["vim.desktop"];
        "application/x-shellscript" = ["vim.desktop"];
        # The plugin's entry, not org.pwmt.zathura.desktop: that one
        # declares no MimeType, the mupdf plugin's does (hidden from
        # menus, NoDisplay). Firefox second, for "Open With". Until now
        # PDFs fell through to LibreOffice Draw.
        "application/pdf" = ["org.pwmt.zathura-pdf-mupdf.desktop" "firefox.desktop"];
        # Thunar (modules/nixos/desktop/thunar.nix). Until now folders went
        # to kitty-open.desktop, which claims inode/directory itself.
        "inode/directory" = ["thunar.desktop"];
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
