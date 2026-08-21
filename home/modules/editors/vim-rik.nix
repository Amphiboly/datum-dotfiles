# home/modules/editors/vim-rik.nix
#
# Preferences: GUI font/theme, driven by the shared theme options.
# Enablement lives in vim.nix.
{
  config,
  lib,
  ...
}: let
  vimGuiFont = "${lib.replaceStrings [" "] ["\\ "] config.theme.font.mono}:h${toString config.theme.font.monoSize}";
in {
  programs.vim.extraConfig = ''
    " Standard graphical GVim font overrides, driven by the shared theme options
    if has("gui_running")
      set guifont=${vimGuiFont}
      set guioptions-=m " Hide standard top application menus to keep desktop workspace clean
      set guioptions-=t " Remove toolbar overlays to match your minimalist aesthetic
    endif

    " Automated plugin commands mapping
    let g:airline_powerline_fonts = 1
    let g:airline_theme = 'dark'
  '';
}
