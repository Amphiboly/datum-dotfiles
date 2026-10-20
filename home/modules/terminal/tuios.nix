# home/modules/terminal/tuios.nix
#
# tuios (github:Gaurav-Gosain/tuios): a terminal multiplexer / window
# manager that runs inside kitty -- tiled panes, workspaces, and named
# sessions held by a daemon, so a project's panes survive closing kitty
# (and, as structure, working directories and scrollback, a reboot). Also
# tracks coding agents in its panes (the Inbox). Per-user settings live in
# tuios-<user>.nix.
#
# From nixpkgs, which can trail upstream's fast releases by a version or
# so; upstream's flake is there if that ever matters.
{pkgs, ...}: {
  home.packages = [pkgs.tuios];
}
