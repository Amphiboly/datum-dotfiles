# home/modules/desktop-integration/umbriel-rik.nix
#
# Umbriel (github:noctalia-dev/umbriel) has no Home Manager module of its own
# -- programs.umbriel in modules/nixos/desktop/umbriel.nix only exposes
# enable/package/portalPackage, nothing config-shaped -- so its config.toml is
# placed directly via home.file. rik's config; see umbriel-guest.nix for
# guest's independently-editable copy. Re-run `umbriel validate` after
# changing assets/rik/umbriel.toml.
_: {
  home.file.".config/umbriel/config.toml".source = ../../../assets/rik/umbriel.toml;
}
