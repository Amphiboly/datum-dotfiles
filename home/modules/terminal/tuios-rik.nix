# home/modules/terminal/tuios-rik.nix
#
# rik's tuios settings, on trial since 2026-10-20 for the kitty workspace:
# one tuios session per project instead of one kitty instance per project.
#
# tuios merges config.d/*.toml under config.toml, and config.toml wins. So
# Home Manager owns this config.d file (read-only), and config.toml stays
# tuios's own: the settings page (prefix+,), `tuios set-config` and the
# keybind manager write there, and a key changed that way overrides the
# value here. `tuios config origin <key>` shows which file a value comes
# from. Leader is the default, ctrl+b.
#
# Theme: Noctalia's tuios community template (enabled in
# assets/rik/noctalia.toml) renders themes/noctalia.json from the shell
# palette, with id "noctalia". tuios watches that directory and repaints
# on a change. The template only runs once ~/.config/tuios exists, which
# this file ensures.
{
  config,
  lib,
  pkgs,
  ...
}: let
  projects = "${config.home.homeDirectory}/Projects";

  # Sessionizer (docs/SESSIONS.md): pick a folder up to two levels under
  # ~/Projects (so datum/datum-config is reachable), then switch to the
  # session named after it, creating it there if needed. Spaces and dots
  # in folder names become dashes in the session name.
  openProject = lib.concatStringsSep " " [
    ''dir=$(${lib.getExe pkgs.fd} --type d --max-depth 2 . ${projects} | ${lib.getExe pkgs.fzf})''
    ''&& tuios switch-session --create --cwd "$dir" "$(basename "$dir" | tr ' .' '--')"''
  ];
in {
  xdg.configFile."tuios/config.d/50-home-manager.toml".source = (pkgs.formats.toml {}).generate "tuios-rik.toml" {
    appearance = {
      theme = "noctalia";
      # z (zoom) fills the pane area with no border or title bar: the
      # "one pane maximised" way of working.
      zoom_borderless = true;
    };
    keybindings.command = [
      {
        name = "open-project";
        key = "prefix+alt+s";
        type = "popup";
        command = openProject;
        description = "Open a project";
      }
    ];
  };
}
