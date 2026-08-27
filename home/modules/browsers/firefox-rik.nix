# home/modules/browsers/firefox-rik.nix
# 2026-08-27 Changed fixed forced bookmarks.nix to sync'd bookmarks
#            via Firefox account sync. Also moved ./bookmarks.nix to
#            this directory from ../../../bookmarks.nix to preserve
#            it in a more appropriate place.
{pkgs, ...}: {
  programs.firefox.profiles.default = {
    settings = {
      "browser.startup.homepage" = "https://nixos.org";
      "browser.search.defaultenginename" = "DuckDuckGo";
    };

    bookmarks = {
      #     force = true;
      #     settings = import ./bookmarks.nix;
      "identity.fxaccounts.enabled" = true;
      "services.sync.engine.bookmarks" = true;
      "services.sync.engine.prefs" = true;
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
