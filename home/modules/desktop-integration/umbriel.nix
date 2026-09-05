# home/modules/desktop-integration/umbriel.nix
#
# Umbriel (github:noctalia-dev/umbriel) has no Home Manager module of its own
# -- programs.umbriel in modules/nixos/desktop/umbriel.nix only exposes
# enable/package/portalPackage, nothing config-shaped -- so its config.toml is
# placed directly via home.file. Baseline config lives in assets/umbriel.toml;
# re-run `umbriel validate` after changing it, and replicate this module for a
# user who needs different settings.
_: {
  home.file.".config/umbriel/config.toml".source = ../../../assets/umbriel.toml;
}
