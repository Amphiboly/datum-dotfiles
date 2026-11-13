# home/modules/editors/helix.nix
#
# Enablement only: LSP/formatter wiring so nix/typst/markdown work for anyone.
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
      };
    };
  };
}
