# home/modules/editors/vim.nix
#
# Enablement only: package, plugins, LSP wiring, and base interface behavior
# anyone would want. See vim-rik.nix for GUI font/theme and the $EDITOR
# default.
#
# LSP client is vim-lsp (+ asyncomplete for the completion popup). The
# vim9script alternative, yegappan/lsp, isn't in nixpkgs. Servers are
# registered with absolute store paths, so nothing has to be on PATH and
# vim-lsp-settings (which downloads servers itself) stays out.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.editors.vim;

  # nixd reads its settings from workspace/configuration. Without a flake
  # it still does completion and diagnostics; option completion needs the
  # flake whose options it should evaluate.
  nixdSettings =
    {
      formatting.command = ["${pkgs.alejandra}/bin/alejandra"];
    }
    // lib.optionalAttrs (cfg.nixd.flake != null) (let
      flake = ''(builtins.getFlake "${cfg.nixd.flake}")'';
      os = "${flake}.nixosConfigurations.${cfg.nixd.host}";
    in {
      nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
      options = {
        nixos.expr = "${os}.options";
        home-manager.expr = "${os}.options.home-manager.users.type.getSubOptions [ ]";
      };
    });

  # Vimscript single-quoted string holding JSON; '' is the only escape.
  toVimJson = v: "json_decode('${lib.replaceStrings ["'"] ["''"] (builtins.toJSON v)}')";
in {
  options.editors.vim.nixd = {
    flake = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = lib.literalExpression ''"''${config.home.homeDirectory}/Projects/datum/datum-config"'';
      description = ''
        Absolute path of the flake nixd evaluates for nixpkgs and option
        completion. null leaves nixd on its defaults.
      '';
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "datum";
      description = "nixosConfigurations attribute whose options nixd offers.";
    };
  };

  config.programs.vim = {
    enable = true;

    # Ensures Home Manager targets the full graphical build package we set up system-wide
    packageConfigurable = pkgs.vim-full;

    # Declarative Plugin Allocations (Completely replaces mutable manual vim_plug setups)
    plugins = with pkgs.vimPlugins; [
      nerdtree
      vim-airline
      vim-airline-themes
      vim-lsp
      asyncomplete-vim
      asyncomplete-lsp-vim
    ];

    extraConfig = ''
      " Core Interface Options
      set number
      set relativenumber
      set mouse=a
      set clipboard=unnamedplus

      " Quick hotkey to toggle NERDTree instantly via terminal or GUI windows
      nnoremap <C-n> :NERDTreeToggle<CR>

      " Language servers. Vim's own filetypes: nix, typst, markdown, and
      " context/tex/plaintex for TeX (which one a .tex file gets depends on
      " g:tex_flavor and the file's first lines).
      augroup lsp_servers
        autocmd!
        autocmd User lsp_setup call lsp#register_server({
          \ 'name': 'nixd',
          \ 'cmd': ['${lib.getExe pkgs.nixd}'],
          \ 'allowlist': ['nix'],
          \ 'workspace_config': {'nixd': ${toVimJson nixdSettings}},
          \ })
        autocmd User lsp_setup call lsp#register_server({
          \ 'name': 'tinymist',
          \ 'cmd': ['${lib.getExe pkgs.tinymist}'],
          \ 'allowlist': ['typst'],
          \ })
        autocmd User lsp_setup call lsp#register_server({
          \ 'name': 'marksman',
          \ 'cmd': ['${lib.getExe pkgs.marksman}', 'server'],
          \ 'allowlist': ['markdown'],
          \ })
        autocmd User lsp_setup call lsp#register_server({
          \ 'name': 'digestif',
          \ 'cmd': ['${pkgs.lua54Packages.digestif}/bin/digestif'],
          \ 'allowlist': ['context', 'tex', 'plaintex', 'bib'],
          \ })
      augroup END

      " Buffer-local maps, only where a server is attached
      function! s:on_lsp_buffer_enabled() abort
        setlocal omnifunc=lsp#complete
        setlocal signcolumn=yes
        setlocal tagfunc=lsp#tagfunc
        nmap <buffer> gd <plug>(lsp-definition)
        nmap <buffer> gr <plug>(lsp-references)
        nmap <buffer> gi <plug>(lsp-implementation)
        nmap <buffer> K <plug>(lsp-hover)
        nmap <buffer> [g <plug>(lsp-previous-diagnostic)
        nmap <buffer> ]g <plug>(lsp-next-diagnostic)
        nmap <buffer> <leader>rn <plug>(lsp-rename)
        nmap <buffer> <leader>ca <plug>(lsp-code-action-float)
        nmap <buffer> <leader>f <plug>(lsp-document-format)
        nmap <buffer> <leader>s <plug>(lsp-document-symbol-search)
      endfunction
      augroup lsp_install
        autocmd!
        autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
      augroup END

      " Format on save: nix through nixd (alejandra),
      " markdown through prettier. A failed prettier run is undone.
      function! s:prettier_markdown() abort
        let l:view = winsaveview()
        silent keepjumps %!${lib.getExe pkgs.prettier} --parser markdown
        if v:shell_error
          silent undo
        endif
        call winrestview(l:view)
      endfunction
      augroup lsp_format
        autocmd!
        autocmd BufWritePre *.nix call execute('LspDocumentFormatSync')
        autocmd BufWritePre *.md call s:prettier_markdown()
      augroup END
    '';
  };
}
