# home/modules/theme/fonts.nix
#
# Single source of truth for interface fonts. App modules read
# config.theme.font.* instead of hardcoding font names/sizes:
# - mono/monoSize: the terminal and editor font (kitty.nix, vim-rik.nix)
# - gui: the desktop shell's font (noctalia-rik.nix, as Noctalia's
#   [shell] font_family; Noctalia's Settings -> Security -> Noctalia
#   Greeter -> Sync carries it on to the login screen)
{lib, ...}: {
  options.theme.font = {
    mono = lib.mkOption {
      type = lib.types.str;
      #     default = "Cascadia Code NF";
      default = "Lilex Nerd Font Mono";
      description = "Monospace font family used by terminal and editor buffers.";
    };
    monoSize = lib.mkOption {
      type = lib.types.int;
      #     default = 12;
      default = 11;
      description = "Point size for the monospace font (terminal text, editor buffer text).";
    };
    gui = lib.mkOption {
      type = lib.types.str;
      default = "Lilex Nerd Font Medium";
      description = "Font family for the desktop shell (Noctalia's bar, launcher and panels).";
    };
  };
}
