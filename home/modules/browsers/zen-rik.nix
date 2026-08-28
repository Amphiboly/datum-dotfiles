# home/modules/browsers/zen-rik.nix
#   by Chat 2026-08-28
#   based on firefox-rik.nix
{pkgs, ...}: {
  programs.zen-browser.profiles.default = {
    settings = {
      "browser.startup.homepage" = "https://nixos.org";

      "identity.fxaccounts.enabled" = true;
      "services.sync.engine.bookmarks" = true;
      "services.sync.engine.prefs" = true;

      # True Compact Mode: Tells Zen to reduce paddings around the sidebar and tabs
      "browser.uidensity" = 1; # 0 = Normal, 1 = Compact, 2 = Touch UI

      # Workspace and Sidebar Mechanics
      "zen.view.compact-sidebar" = true; # Keeps the vertical sidebar narrow/icon-only by default
      "zen.view.hover-sidebar" = false; # Set to true if you want the sidebar 100% hidden until mouse hover
      "zen.workspaces.show-workspace-indicator" = true; # Keeps a subtle visual cue for your active context

      # Tab Behavior adjustments
      "browser.tabs.closeWindowWithLastTab" = false; # Prevent Zen from completely crashing out if you close the last active tab
      "browser.tabs.loadInBackground" = true; # Prevent links you click from stealing focus away from your active view
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

    bookmarks = {};

    extensions = {
      force = true;
      packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ghostery
        onepassword-password-manager # Cleaner setup without Sidebery
      ];
    };
  };
}
