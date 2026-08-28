# bookmarks.nix
[
  {
    name = "Bookmarks Toolbar";
    toolbar = true;
    bookmarks = [
      {
        name = "NixOS Homepage";
        url = "https://nixos.org";
      }
      {
        name = "Nix Packages Search";
        url = "https://nixos.org";
      }
    ];
  }
  {
    name = "Development";
    bookmarks = [
      {
        name = "GitHub";
        tags = ["git" "code"];
        url = "https://github.com";
      }
    ];
  }
]
