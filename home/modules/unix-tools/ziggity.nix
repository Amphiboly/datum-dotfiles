# home/modules/unix-tools/ziggity.nix
#
# ziggity (github:simoarpe/ziggity): a lazygit-style terminal UI for git,
# written in Zig, on trial as gitui's replacement (gitui.nix stays until
# that is decided). Over gitui it adds interactive rebase, the commit graph,
# range selection, custom patches, undo via the reflog, worktrees, and an
# optional AI hook for commit messages. It drives the `git` on PATH (no
# libgit2), so ssh goes through SSH_AUTH_SOCK, here 1Password's agent. Not
# in nixpkgs; built from source in pkgs/ziggity.
#
# Config: ziggity reads no global file of its own (no XDG lookup), only
# $ZIGGITY_CONFIG and then a repo's .ziggity.ini, so the variable points it
# at the file below. As a session variable it reaches shells started after
# the next login. Every setting, key and colour: docs/configuration.md
# upstream.
#
# Colours are terminal palette indices, so like gitui it already follows
# kitty's palette, i.e. Noctalia's. Keys are vi-style out of the box
# (hjkl, ? for help), so nothing is remapped.
{
  config,
  pkgs,
  ...
}: let
  configFile = "${config.xdg.configHome}/ziggity/config.ini";
in {
  home.packages = [(pkgs.callPackage ../../../pkgs/ziggity {})];

  home.sessionVariables.ZIGGITY_CONFIG = configFile;

  xdg.configFile."ziggity/config.ini".text = ''
    # Managed by Home Manager (home/modules/unix-tools/ziggity.nix).
    # A repo's .ziggity.ini overrides this per repo.

    # Background `git fetch` every 60 s (the default) is off. The remotes
    # here are ssh, i.e. 1Password's agent, and a fetch firing on a timer
    # could pop a 1Password unlock or approval prompt at random. A
    # precaution, not something observed: set 60 to try it. `f` fetches
    # by hand, and the incoming count updates after that.
    fetch_interval_secs = 0
  '';
}
