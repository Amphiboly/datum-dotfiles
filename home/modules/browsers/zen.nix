# home/modules/browsers/zen.nix
#   by Chat 2026-08-28
#   based on firefox.nix
{inputs, ...}: {
  imports = [
    # Import the home-manager module natively provided by the flake
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser = {
    enable = true;

    # No `package =` here. homeModules.default is the beta track, and the
    # module builds its own package from `beta-unwrapped`, baking `policies`
    # into it. Setting the flake's prebuilt `.beta` (already wrapped) replaced
    # that, and home-manager warned that 'policies', 'pkcs11Modules' and
    # 'configPath' would be dropped. For another track import
    # homeModules.twilight instead, or set `unwrappedPackage`.

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
