# home/modules/editors/helix-rik.nix
#
# Preferences: theme, editor appearance, keybindings, and the flake nixd
# evaluates. Enablement lives in helix.nix. Vim stays the default editor
# (vim-rik.nix); helix is there to be run as `hx`.
#
# The theme is Noctalia's: its built-in helix template (listed in
# assets/rik/noctalia.toml) renders ~/.config/helix/themes/noctalia.toml
# from the shell palette. Its post hook (5.5) sends SIGUSR1 to running hx
# processes, which makes them reload config, so open editors follow palette
# changes. Until Noctalia first renders the file, helix falls back to its
# default theme with a warning.
{config, ...}: let
  flake = ''(builtins.getFlake "${config.home.homeDirectory}/Projects/datum/datum-config")'';
  os = "${flake}.nixosConfigurations.datum";
in {
  # Same expressions as vim's nixd settings (vim.nix): nixpkgs, NixOS and
  # Home Manager option completion from this repo.
  programs.helix.languages.language-server.nixd.config.nixd = {
    nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
    options = {
      nixos.expr = "${os}.options";
      home-manager.expr = "${os}.options.home-manager.users.type.getSubOptions [ ]";
    };
  };

  programs.helix.settings = {
    theme = "noctalia";

    editor = {
      line-number = "relative";
      cursorline = true;
      bufferline = "multiple";

      cursor-shape = {
        normal = "block";
        insert = "bar";
        select = "underline";
      };

      search.smart-case = false;

      indent-guides = {
        render = true;
        character = "┋";
        skip-levels = 1;
      };

      whitespace.characters = {
        space = " ";
        tab = "→";
        newline = "⏎";
      };

      file-picker.hidden = false;

      statusline = {
        separator = "│";
        left = ["mode" "spacer" "spinner" "version-control" "spacer" "file-name" "file-modification-indicator"];
        center = [];
        right = ["diagnostics" "workspace-diagnostics" "selections" "position" "position-percentage" "file-type"];

        mode = {
          normal = "NORMAL";
          insert = "INSERT";
          select = "VISUAL";
        };
      };

      lsp.display-inlay-hints = true;
    };

    keys.normal = {
      z = {
        w = ":set soft-wrap.enable true";
        W = ":set soft-wrap.enable false";
      };

      "tab" = ":buffer-next";
      "S-tab" = ":buffer-previous";
      "C-p" = ":lsp-workspace-command tinymist.pinMain \"%sh{realpath %{buffer_name}}\"";
      "C-w" = ":buffer-close";
      "backspace" = "goto_next_diag";
      "X" = ["select_mode" "extend_line"];

      # Interactive TTY yazi picker link
      C-y = ":sh yazi \"%{buffer_name}\" --chooser-file=/tmp/yazi-helix-picker; if [ -f /tmp/yazi-helix-picker ]; then hx_open=$(cat /tmp/yazi-helix-picker); rm -f /tmp/yazi-helix-picker; helix -c \":open '$hx_open'\"; fi";

      space = {
        T = ":sh typst compile \"%{buffer_name}\"";
        x = ":toggle whitespace.render all none";
      };
    };
  };
}
