# home/modules/editors/vim-rik.nix
#
# Preferences: GUI font/theme, driven by the shared theme options, plus the
# $EDITOR default and ConTeXt as the .tex flavour. Enablement lives in
# vim.nix.
#
# Noctalia ships no vim template (5.4), so vim isn't on the shared palette.
{
  config,
  lib,
  ...
}: let
  vimGuiFont = "${lib.replaceStrings [" "] ["\\ "] config.theme.font.mono}:h${toString config.theme.font.monoSize}";
in {
  home.sessionVariables.EDITOR = "vim";

  # nixd evaluates this repo for nixpkgs, NixOS and Home Manager options.
  editors.vim.nixd.flake = "${config.home.homeDirectory}/Projects/datum/datum-config";

  programs.vim.extraConfig = ''
    " .tex files without telltale first lines are ConTeXt, not plain TeX
    let g:tex_flavor = 'context'

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
