# home/modules/unix-tools/fastfetch-rik.nix
#
# rik's fastfetch config, written by Home Manager to
# ~/.config/fastfetch/config.jsonc. fastfetch reads that ahead of the
# system-wide /etc/fastfetch/config.jsonc (modules/nixos/fastfetch.nix),
# which stays as the default for other users. zsh-rik.nix runs it at every
# interactive shell start, adding the NixOS logo on the command line.
#
# It's a Home Manager module so it can read Home Manager values at build
# time instead of running commands at every shell start:
# - the GUI and terminal fonts from theme.font (theme/fonts.nix). On
#   Umbriel fastfetch's own font module finds nothing (it reads GTK/Qt/DE
#   font settings, and there are none), and terminalfont only works from
#   inside the terminal it describes.
# - Noctalia's version from the package Home Manager runs. Noctalia isn't
#   a desktop environment fastfetch recognises ("No DE found").
# What fastfetch can detect itself (WM, login manager, terminal and editor
# versions) it still does, with `format` adding the rest. A font picked at
# runtime in Noctalia's own Settings is not shown; this shows theme.font.gui.
#
# Key icons are Nerd Font glyphs, written as JSON escapes (decoded by
# `nf`) so the codepoints stay readable here. The kitty font is a Nerd Font.
{config, ...}: let
  inherit (config.theme) font;
  nf = escape: builtins.fromJSON ''"${escape}"'';

  # fastfetch's editor module shows one editor: $VISUAL if set, else
  # $EDITOR. While only EDITOR is set (vim-rik.nix), that's enough. Once
  # home.sessionVariables.VISUAL names a different editor, the line runs
  # the module twice instead, once with VISUAL cleared so it falls back to
  # EDITOR, and shows both. (A VISUAL set outside Home Manager isn't seen
  # here; the plain module would then show only the visual editor.)
  vars = config.home.sessionVariables;
  hasVisual = vars ? VISUAL && vars.VISUAL != (vars.EDITOR or null);
  editorIcon = nf "\\udb85\\udf8e";
  editorLine =
    if hasVisual
    then {
      type = "command";
      key = "Editor";
      keyIcon = editorIcon;
      text = ''
        q='.[0].result | [.name, .version] | map(select(. != "")) | join(" ")'
        v=$(fastfetch --format json -s editor | jq -r "$q")
        e=$(VISUAL= fastfetch --format json -s editor | jq -r "$q")
        echo "$v (visual), $e (text)"
      '';
    }
    else {
      type = "editor";
      key = "Editor";
      keyIcon = editorIcon;
      format = "{name} {version}";
    };
in {
  programs.fastfetch = {
    enable = true;
    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
      logo.padding = {
        left = 1;
        top = 4;
      };
      display = {
        key = {
          type = "both";
          width = 12;
        };
        separator = " ";
      };
      modules = [
        "title"
        "separator"
        "os"
        "kernel"
        "packages"
        {
          type = "custom";
          key = "DE";
          keyIcon = nf "\\udb81\\udd94"; # nf-md-weather_night
          format = "Noctalia ${config.programs.noctalia.package.version}";
        }
        {
          type = "lm";
          key = "LM";
          format = "Noctalia Greeter ({service})";
        }
        {
          type = "wm";
          key = "WM";
          keyIcon = nf "\\uf488";
          format = "{pretty-name} {protocol-name} – ${font.gui}";
        }
        "shell"
        {
          type = "terminal";
          key = "Terminal";
          keyIcon = nf "\\ue795";
          format = "{pretty-name} {version} – ${font.mono} (${toString font.monoSize}pt)";
        }
        editorLine
        "separator"
        "host"
        "cpu"
        "gpu"
        "memory"
        "disk"
        "swap"
        "uptime"
        "separator"
        {
          type = "colors";
          symbol = "circle";
        }
      ];
    };
  };
}
