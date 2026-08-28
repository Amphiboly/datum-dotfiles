# home/modules/browsers/zen.nix
#   by Chat 2026-08-28
#   based on firefox.nix
{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    # Import the home-manager module natively provided by the flake
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser = {
    enable = true;

    # Select the track containing Firefox Sync (defaults to standard stable release,
    # but you can explicitly bind it to beta if needed)
    package = inputs.zen-browser.packages."${pkgs.system}".beta;

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
