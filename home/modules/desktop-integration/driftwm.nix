# home/modules/desktop-integration/driftwm.nix
#
# The shared half of driftwm's per-user setup (the session itself is
# modules/nixos/desktop/driftwm.nix): upstream's Home Manager module, which
# renders `settings` to ~/.config/driftwm/config.toml and checks it with
# `driftwm --check-config` at build time, so a bad config fails the build
# instead of the session. Each user adds a driftwm-<user>.nix that supplies
# `settings` (driftwm-rik.nix).
#
# The module's other defaults duplicate what the NixOS module already does
# system-wide, so they're switched off here:
# - systemd units and xwayland-satellite: installed by programs.driftwm;
# - portals: likewise, and a user-level xdg.portal would be one more place
#   for portal config to diverge;
# - services.gnome-keyring: the system keyring already runs (unlocked by PAM
#   at login); this would start a second, unconditional daemon in every
#   session, COSMIC's and Umbriel's included.
#
# The option stub works around a clash between upstream's module and Home
# Manager's services.way-displays (not enabled here): way-displays maps over
# *every* wayland.windowManager.<name> and defines systemd.variables on each,
# which all of HM's own WM modules declare and driftwm's out-of-tree one
# doesn't. The definition sits under mkIf false, but the module system still
# rejects a definition for an undeclared option, so every HM eval fails with
# "The option `wayland.windowManager.driftwm.systemd.variables' does not
# exist". Declaring it (unused, internal) satisfies that. Drop the stub once
# upstream declares it.
{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.driftwm.homeModules.default];

  options.wayland.windowManager.driftwm.systemd.variables = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    internal = true;
    description = "Unused; see the comment in driftwm.nix.";
  };

  config = {
    wayland.windowManager.driftwm = {
      enable = true;
      systemd.enable = false;
      xwaylandSatellitePackage = null;
      extraPortals = [];
    };

    services.gnome-keyring.enable = false;
  };
}
