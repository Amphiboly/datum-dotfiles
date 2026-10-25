# home/modules/desktop-integration/driftwm.nix
#
# driftwm's per-user setup (the session itself is
# modules/nixos/desktop/driftwm.nix), shared by every user who imports it.
#
# Each user's config is assets/<user>/driftwm.toml (desktop.driftwm.file):
# driftwm's full commented reference config with that user's changes
# uncommented, kept whole so it can be diffed against a new release's (like
# kitty.conf). It's deployed verbatim rather than through upstream's
# `wayland.windowManager.driftwm.settings`, which would re-render it and drop
# every comment, but still goes through `driftwm --check-config` at build
# time, so a bad config fails the build instead of the session. To check
# edits without a rebuild:
# `driftwm --check-config --config assets/<user>/driftwm.toml`.
#
# Upstream's Home Manager module is still imported, for the package and for
# options other modules expect to find. Its other defaults duplicate what the
# NixOS module already does system-wide, so they're switched off here:
# - systemd units and xwayland-satellite: installed by programs.driftwm;
# - portals: likewise, and a user-level xdg.portal would be one more place
#   for portal config to diverge;
# - services.gnome-keyring: the system keyring already runs (unlocked by PAM
#   at login); this would start a second, unconditional daemon in every
#   session, COSMIC's and Umbriel's included.
#
# The systemd.variables stub works around a clash between upstream's module
# and Home Manager's services.way-displays (not enabled here): way-displays
# maps over *every* wayland.windowManager.<name> and defines systemd.variables
# on each, which all of HM's own WM modules declare and driftwm's out-of-tree
# one doesn't. The definition sits under mkIf false, but the module system
# still rejects a definition for an undeclared option, so every HM eval fails
# with "The option `wayland.windowManager.driftwm.systemd.variables' does not
# exist". Declaring it (unused, internal) satisfies that. Drop the stub once
# upstream declares it.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.desktop.driftwm;
  driftwm = config.wayland.windowManager.driftwm.package;
in {
  imports = [inputs.driftwm.homeModules.default];

  options = {
    desktop.driftwm.file = lib.mkOption {
      type = lib.types.path;
      default = ../../.. + "/assets/${config.home.username}/driftwm.toml";
      defaultText = lib.literalExpression ''../../.. + "/assets/''${config.home.username}/driftwm.toml"'';
      description = "driftwm config.toml to deploy, checked at build time.";
    };

    wayland.windowManager.driftwm.systemd.variables = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      internal = true;
      description = "Unused; see the comment in driftwm.nix.";
    };
  };

  config = {
    wayland.windowManager.driftwm = {
      enable = true;
      systemd.enable = false;
      xwaylandSatellitePackage = null;
      extraPortals = [];
    };

    xdg.configFile."driftwm/config.toml".source = pkgs.runCommand "driftwm-config.toml" {nativeBuildInputs = [driftwm];} ''
      cp ${cfg.file} $out
      ${lib.getExe driftwm} --check-config --config $out
    '';

    services.gnome-keyring.enable = false;
  };
}
