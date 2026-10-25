# home/modules/desktop-integration/driftwm-rik.nix
#
# rik's driftwm config lives in assets/rik/driftwm.toml: driftwm's full
# commented reference config with rik's changes uncommented, kept whole so
# it can be diffed against a new release's (like kitty.conf). It's deployed
# verbatim rather than through the HM module's `settings`, which would
# re-render it and drop every comment, but still goes through
# `driftwm --check-config` at build time, so a bad config fails the build
# instead of the session. To check edits without a rebuild:
# `driftwm --check-config --config assets/rik/driftwm.toml`.
{
  config,
  lib,
  pkgs,
  ...
}: {
  xdg.configFile."driftwm/config.toml".source =
    pkgs.runCommand "driftwm-config.toml" {
      nativeBuildInputs = [config.wayland.windowManager.driftwm.package];
    } ''
      cp ${../../../assets/rik/driftwm.toml} $out
      ${lib.getExe config.wayland.windowManager.driftwm.package} --check-config --config $out
    '';
}
