# home/modules/theme/fonts.nix
#
# Single source of truth for interface fonts. App modules (kitty, zed, vim,
# helix) read config.theme.font.* instead of hardcoding font names/sizes.
{lib, ...}: {
  options.theme.font = {
    mono = lib.mkOption {
      type = lib.types.str;
      default = "Cascadia Code NF";
      description = "Monospace font family used by terminal and editor buffers.";
    };
    monoSize = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "Point size for the monospace font (terminal text, editor buffer text).";
    };
    uiSize = lib.mkOption {
      type = lib.types.int;
      default = 15;
      description = "Point size for application UI/chrome text (e.g. Zed's interface font).";
    };
  };
}
