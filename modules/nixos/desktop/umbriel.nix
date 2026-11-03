# modules/nixos/desktop/umbriel.nix
#
# Umbriel (github:noctalia-dev/umbriel): the wlroots-based Wayland compositor
# behind Noctalia v5, and since 2026-11-03 the only session (COSMIC, its
# predecessor, is in tag last-cosmic). The greeter finds it through
# services.displayManager.sessionPackages, which this module's upstream
# nixosModule populates itself. Face auth is in facial-auth.nix: greetd's
# PAM stack at login, "login" for Noctalia's lock screen.
#
# The Noctalia shell and Umbriel's own config.toml are both per-user, so they
# live in home/modules/desktop-integration/{noctalia,umbriel}.nix rather than
# here. programs.umbriel here only exposes enable/package/portalPackage --
# there's no NixOS-level settings option to hang config on.
#
# `package` and `portalPackage` are left at the upstream module's defaults:
# the flake's own packages, built on umbriel's pinned nixpkgs, which is what
# umbriel.cachix.org holds. (Until 2026-10-15 this used `pkgs.umbriel` from
# umbriel's overlay, built against our whole overlay stack, which no cache
# could match.)
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  # See the comment on the umbriel input in flake.nix: the compositor loads
  # the system's Mesa, so its glibc must not be older than ours.
  theirGlibc = inputs.umbriel.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.glibc.version;
in {
  imports = [inputs.umbriel.nixosModules.default];

  programs.umbriel.enable = true;

  assertions = [
    {
      assertion = lib.versionAtLeast theirGlibc pkgs.glibc.version;
      message = ''
        umbriel's pinned nixpkgs has glibc ${theirGlibc}, older than ours
        (${pkgs.glibc.version}); it would fail to load the system's Mesa
        ("eglGetDisplay failed"). Wait for upstream to bump its nixpkgs
        (checked hourly), then update the umbriel input again.
      '';
    }
  ];
}
