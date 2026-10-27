# home/modules/editors/helix-rik.nix
#
# Preferences: theme, editor appearance, and keybindings. Enablement lives
# in helix.nix. Vim is the default editor now; see vim-rik.nix.
#
# The theme is Noctalia's: its built-in helix template renders
# ~/.config/helix/themes/noctalia.toml from the shell palette. Helix doesn't
# watch theme files, so after a palette change run `:theme noctalia` (or
# `:config-reload`) in open editors. Space n d / Space n n still switch to
# the fixed light/dark themes from theme/colors.nix, for the session only.
{config, ...}: {
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

      search = {
        smart-case = false;
      };

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

      file-picker = {
        hidden = false;
      };

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

      lsp = {
        display-inlay-hints = true;
      };
    };

    keys.normal.z = {
      w = ":set soft-wrap.enable true";
      W = ":set soft-wrap.enable false";
    };

    keys.normal = {
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

        # Space + n opens the menu, then tap 'd' (day) or 'n' (night)
        n = {
          d = ":theme ${config.theme.colorScheme.light}";
          n = ":theme ${config.theme.colorScheme.dark}";
        };
      };
    };
  };
}
