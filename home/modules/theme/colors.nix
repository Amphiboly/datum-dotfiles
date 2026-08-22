# home/modules/theme/colors.nix
#
# Names of the light/dark color themes, in Helix's naming, since Helix is the
# only app here with a static default + manual light/dark keybind. Kitty
# already switches automatically based on the OS light/dark preference via
# autoThemeFiles, and keeps its own theme-catalog names independently.
{lib, ...}: {
  options.theme.colorScheme = {
    light = lib.mkOption {
      type = lib.types.str;
      default = "onelight";
      description = "Name of the light-mode color theme (Helix theme catalog).";
    };
    dark = lib.mkOption {
      type = lib.types.str;
      default = "catppuccin_mocha";
      description = "Name of the dark-mode color theme (Helix theme catalog).";
    };
  };
}
