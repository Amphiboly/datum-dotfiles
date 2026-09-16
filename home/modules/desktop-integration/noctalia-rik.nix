# home/modules/desktop-integration/noctalia-rik.nix
#
# rik's Noctalia settings, split out from the shared enable/package logic in
# noctalia.nix so guest can carry an independently-editable config instead of
# sharing rik's (see noctalia-guest.nix). Noctalia's own settings UI is still
# the right place for further tweaks; re-export from there and drop the
# result back into assets/rik/noctalia.toml to update this baseline.
_: {
  programs.noctalia.settings = ../../../assets/rik/noctalia.toml;
}
