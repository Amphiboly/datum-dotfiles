# home/modules/desktop-integration/compose-key.nix
#
# What the Compose key produces. Which key *is* Compose is the compositor's
# business: Umbriel reads it from [input.keyboard] options in
# assets/<user>/umbriel.toml (RAlt for rik).
_: {
  home.file.".XCompose".source = ../../../assets/xcompose-vim;
}
