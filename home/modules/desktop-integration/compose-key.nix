# home/modules/desktop-integration/compose-key.nix
#
# What the Compose key produces. Which key *is* Compose is set per session:
# COSMIC reads it from com.system76.CosmicComp's xkb_config
# (options: "...,compose:ralt"), carried in rik's COSMIC snapshot
# (assets/rik/cosmic.toml, see cosmic-snapshot.nix); Umbriel from
# [input.keyboard] options in assets/rik/umbriel.toml.
#
# This module used to also write ~/.config/cosmic/com.system76.CosmicInput/
# v1/keys with xkb_options: Some("compose:ralt"). Nothing in COSMIC 1.9
# reads a CosmicInput component (checked by grepping the cosmic-comp,
# -settings, -settings-daemon and -applets binaries), so it was a no-op; the
# working setting has always been the CosmicComp one.
_: {
  home.file.".XCompose".source = ../../../assets/xcompose-vim;
}
