# home/modules/theme/colors.nix
#
# Names of the light/dark color themes, in Helix's naming. For rik these
# are only the fixed fallbacks behind Helix's Space n d / Space n n
# keybinds; the default theme for rik's helix and kitty now comes from
# Noctalia's templates (helix-rik.nix, kitty-rik.nix). Kitty for guest
# still switches on the OS light/dark preference via its own
# autoThemeFiles, with kitty theme-catalog names kept independently.
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
