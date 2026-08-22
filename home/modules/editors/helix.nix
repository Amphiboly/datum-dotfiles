# home/modules/editors/helix.nix
#
# Enablement only: LSP/formatter wiring so nix/typst/markdown work for anyone.
# See helix-rik.nix for theme, keybindings, and the $EDITOR default.
{pkgs, ...}: {
  home.packages = [pkgs.nixd pkgs.tinymist];

  programs.helix = {
    enable = true;

    # LANGUAGES STANZA: compiles natively into languages.toml
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          language-servers = ["nixd"];
          formatter = {command = "${pkgs.alejandra}/bin/alejandra";};
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
            command = "${pkgs.prettier}/bin/prettier";
            args = ["--parser" "markdown"];
          };
        }
      ];

      language-server = {
        # Advanced Nixd Engine with Deep Flake Evaluation Integration
        nixd = {
          command = "${pkgs.nixd}/bin/nixd";
          args = ["--semantic-tokens=true"];

          # Use Nix multiline string symbols (''...) to protect the internal quotes
          config.nixd = {
            nixpkgs.expr = ''import (builtins.getFlake "$root").inputs.nixpkgs { }'';
            options = {
              nixos.expr = ''(builtins.getFlake "$root").nixosConfigurations."datum-laptop".options'';
            };
          };
        };

        tinymist = {
          command = "${pkgs.tinymist}/bin/tinymist";
        };
        marksman = {
          command = "${pkgs.marksman}/bin/marksman";
        };
      };
    };
  };
}
