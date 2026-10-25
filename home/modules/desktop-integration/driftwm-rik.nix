# home/modules/desktop-integration/driftwm-rik.nix
#
# rik's driftwm config, kept as plain TOML in assets/rik/driftwm.toml (like
# umbriel.toml) and fed through the HM module's `settings` so it's validated
# at build time (see driftwm.nix). To check edits without a rebuild:
# `driftwm --check-config --config assets/rik/driftwm.toml`.
_: {
  wayland.windowManager.driftwm.settings =
    builtins.fromTOML (builtins.readFile ../../../assets/rik/driftwm.toml);
}
