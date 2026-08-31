# home/modules/browsers/firefox-rik.nix
# 2026-08-28 Added settings and search settings in common with zen
# 2026-08-27 Changed fixed forced bookmarks.nix to sync'd bookmarks
#            via Firefox account sync. Also moved ./bookmarks.nix to
#            this directory from ../../../bookmarks.nix to preserve
#            it in a more appropriate place.
{pkgs, ...}: {
  programs.firefox.profiles.default = {
    settings = {
      "browser.startup.homepage" = "https://nixos.org";
      "identity.fxaccounts.enabled" = true;
      "services.sync.engine.bookmarks" = true;

      # True Compact Mode: Tells Firefox to reduce paddings around the sidebar and tabs
      "browser.uidensity" = 1; # 0 = Normal, 1 = Compact, 2 = Touch UI
      # Tab Behavior adjustments
      "browser.tabs.closeWindowWithLastTab" = false; # Prevent Firefox from completely crashing out if you close the last active tab
      "browser.tabs.loadInBackground" = true; # Prevent links you click from stealing focus away from your active view
      "services.sync.engine.prefs" = true;
    };

    search = {
      force = true; # Force true ensures these clean target templates overwrite any broken database entries
      default = "ddg";

      engines = {
        "NixOS Packages" = {
          urls = [{template = "https://search.nixos.org/packages?query={searchTerms}";}];
          icon = "https://nixos.org";
          definedAliases = ["@np"];
        };
        "NixOS Options" = {
          urls = [{template = "https://search.nixos.org/options?query={searchTerms}";}];
          icon = "https://nixos.org";
          definedAliases = ["@no"];
        };
        "GitHub" = {
          urls = [{template = "https://github.com{searchTerms}&type=repositories";}];
          icon = "https://github.com";
          definedAliases = ["@gh"];
        };
      };
    };

    bookmarks = {
      #     force = true;
      #     settings = import ./bookmarks.nix;
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
