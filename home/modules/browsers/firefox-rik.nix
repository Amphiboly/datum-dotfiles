# home/modules/browsers/firefox-rik.nix
{pkgs, ...}: {
  programs.firefox.profiles.default = {
    settings = {
      "browser.startup.homepage" = "https://nixos.org";
      "browser.search.defaultenginename" = "DuckDuckGo";
    };

    bookmarks = {
      force = true;
      settings = import ../../../bookmarks.nix;
    };

    # Nested extensions block with local scoped variables
    extensions = {
      force = true;
      packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ghostery
        sidebery
        onepassword-password-manager
      ];
    };
  };
}
