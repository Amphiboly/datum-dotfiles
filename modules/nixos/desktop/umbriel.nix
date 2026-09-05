# modules/nixos/desktop/umbriel.nix
#
# Umbriel (github:noctalia-dev/umbriel): the wlroots-based Wayland compositor
# behind Noctalia v5, added here as a second selectable session next to
# COSMIC rather than a replacement. cosmic-greeter stays the active greeter
# and keeps discovering this session the same way it discovers COSMIC's --
# via services.displayManager.sessionPackages, which this module's upstream
# nixosModule populates itself. That also means pam_gaze (facial-auth.nix)
# needs no changes: it is wired to the cosmic-greeter PAM service, which
# still fronts login and lock regardless of which session gets picked.
#
# The Noctalia shell that runs on top of Umbriel is per-user, so it lives in
# home/modules/desktop-integration/noctalia.nix rather than here.
#
# Should separate config files per user be needed for Umbriel this should be split
# and part or all moved to home/modules/desktop-integration
{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.umbriel.nixosModules.default];

  programs.umbriel = {
    enable = true;
    package = pkgs.umbriel;
    settings = ../../../assets/umbriel.toml;
  };
}
