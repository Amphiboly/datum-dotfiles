# home/modules/desktop-integration/umbriel-guest.nix
#
# guest's Umbriel config.toml, placed via home.file like umbriel-rik.nix --
# see that file for why there's no shared programs.umbriel HM module to hang
# this on. Currently a copy of rik's config (assets/rik/umbriel.toml); edit
# assets/guest/umbriel.toml directly to diverge, then `umbriel validate` it.
_: {
  home.file.".config/umbriel/config.toml".source = ../../../assets/guest/umbriel.toml;
}
