# home/modules/editors/vim.nix
#
# Enablement only: package, plugins, and base interface behavior anyone
# would want. See vim-rik.nix for GUI font/theme.
{pkgs, ...}: {
  programs.vim = {
    enable = true;

    # Ensures Home Manager targets the full graphical build package we set up system-wide
    packageConfigurable = pkgs.vim-full;

    # Declarative Plugin Allocations (Completely replaces mutable manual vim_plug setups)
    plugins = with pkgs.vimPlugins; [
      nerdtree
      vim-airline
      vim-airline-themes
    ];

    extraConfig = ''
      " Core Interface Options
      set number
      set relativenumber
      set mouse=a
      set clipboard=unnamedplus

      " Quick hotkey to toggle NERDTree instantly via terminal or GUI windows
      nnoremap <C-n> :NERDTreeToggle<CR>
    '';
  };
}
