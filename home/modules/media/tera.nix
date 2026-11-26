# home/modules/media/tera.nix
#
# tera (github:shinokada/tera): internet radio in the terminal. It
# searches Radio Browser, keeps favourite lists, and plays through mpv,
# so music files stay with mpv itself (mpv.nix) and tera is for streams.
# Not in nixpkgs; built from source in pkgs/tera. Added 2026-11-26.
#
# It runs the `mpv` on PATH, i.e. programs.mpv from mpv.nix, without
# --no-config, so mpv.conf applies; nothing in it matters for a stream.
#
# Config is left to tera: ~/.config/tera/ holds config.yaml (written by
# its own Settings menu: theme, shuffle, reconnect, ...) and data/
# (favourites, ratings, tags, blocklist). Managing any of it from Home
# Manager would make it read-only and break those menus. /home isn't
# wiped at boot, so it persists as is.
#
# Colours are ANSI palette indices (0-15), so it follows kitty's palette,
# i.e. Noctalia's. The optional gist sync keeps its GitHub token in the
# Secret Service, which gnome-keyring provides here.
#
# Settings -> About guesses how tera was installed and suggests an
# update command; it doesn't know Nix. Updates come from bumping
# pkgs/tera.
{pkgs, ...}: {
  home.packages = [(pkgs.callPackage ../../../pkgs/tera {})];
}
