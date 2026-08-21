# home/modules/browsers/firefox.nix
#
# Generic mechanism + sane defaults only — no personal bookmarks, extensions,
# homepage, or search engine here. See firefox-rik.nix for that, imported
# only by profiles that want it.
{...}: {
  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      name = "Default";
      isDefault = true;

      settings = {
        "browser.aboutwelcome.enabled" = false;
        "signon.rememberSignons" = false;
        "privacy.resistFingerprinting" = true;
        "extensions.autoDisableScope" = 0;
      };
    };
  };
}
