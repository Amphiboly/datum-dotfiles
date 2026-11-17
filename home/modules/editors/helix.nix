# home/modules/editors/helix.nix
#
# Enablement only: LSP/formatter wiring so nix/typst/markdown and TeX
# (ConTeXt, LaTeX, BibTeX via digestif) work for anyone.
# See helix-rik.nix for theme, keybindings and the flake nixd evaluates.
# Helix is not the default editor; $EDITOR is vim (vim-rik.nix).
#
# Servers are referenced by absolute store path, so nothing has to be on
# PATH.
{
  lib,
  pkgs,
  ...
}: {
  programs.helix = {
    enable = true;

    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          language-servers = ["nixd"];
          formatter.command = lib.getExe pkgs.alejandra;
        }
        {
          name = "typst";
          auto-format = true;
          language-servers = ["tinymist"];
        }
        {
          name = "markdown";
          auto-format = true;
          language-servers = ["marksman"];
          formatter = {
            command = lib.getExe pkgs.prettier;
            args = ["--parser" "markdown"];
          };
        }
        # ConTeXt: Helix has no language for it, so .mkiv/.mkvi/.mkxl/.mklx
        # had none at all. Highlighting borrows the LaTeX grammar (queries
        # inherited below); digestif is the server, as in vim.nix, and is
        # told it's ConTeXt by the language name. .tex stays LaTeX here
        # (vim instead defaults it to ConTeXt via g:tex_flavor).
        {
          name = "context";
          scope = "source.context";
          file-types = ["mkiv" "mkvi" "mkxl" "mklx" "mkii"];
          comment-token = "%";
          grammar = "latex";
          language-servers = ["digestif"];
        }
        # digestif instead of the default texlab, which isn't installed.
        {
          name = "latex";
          language-servers = ["digestif"];
        }
        {
          name = "bibtex";
          language-servers = ["digestif"];
        }
      ];

      language-server = {
        nixd = {
          command = lib.getExe pkgs.nixd;
          args = ["--semantic-tokens=true"];
        };
        tinymist.command = lib.getExe pkgs.tinymist;
        marksman = {
          command = lib.getExe pkgs.marksman;
          args = ["server"];
        };
        digestif.command = "${pkgs.lua54Packages.digestif}/bin/digestif";
      };
    };
  };

  # Queries are looked up by language name, so "context" needs its own,
  # here just LaTeX's.
  xdg.configFile = lib.genAttrs [
    "helix/runtime/queries/context/highlights.scm"
    "helix/runtime/queries/context/textobjects.scm"
  ] (_: {text = "; inherits: latex\n";});
}
