# home/modules/desktop-integration/umbriel-rik.nix
#
# Umbriel (github:noctalia-dev/umbriel) has no Home Manager module of its own
# -- programs.umbriel in modules/nixos/desktop/umbriel.nix only exposes
# enable/package/portalPackage, nothing config-shaped -- so its config.toml is
# placed directly via home.file. rik's config; see umbriel-guest.nix for
# guest's independently-editable copy. After changing assets/rik/umbriel.toml,
# re-run `umbriel config validate -c assets/rik/umbriel.toml`.
#
# umbriel-outputs-reset backs the Mod+Shift+O bind. After the idle blank
# (both screens off, then on) Umbriel wakes eDP-1 but fails to bring an
# external monitor back ("Swapchain for output 'DP-2' failed test"); the
# same happens on hotplug while eDP-1 is lit. A plain dpms-on keeps
# failing, while disabling and re-enabling the output relights it (tested
# 2026-10-27 on the LG ultrawide, HDMI). Upstream: noctalia-dev/umbriel#218.
# The connector name moves between DP-1 and DP-2, so every output except
# the panel is cycled. `umbriel` itself comes from the system profile.
{pkgs, ...}: {
  home.file.".config/umbriel/config.toml".source = ../../../assets/rik/umbriel.toml;

  home.packages = [
    (pkgs.writeShellApplication {
      name = "umbriel-outputs-reset";
      runtimeInputs = [pkgs.gawk pkgs.coreutils];
      text = ''
        for out in $(umbriel outputs | awk '/^[^ \t]/ && $1 !~ /^eDP-/ {print $1}'); do
          umbriel msg output-disable "$out"
          sleep 1
          umbriel msg output-enable "$out"
        done
      '';
    })
  ];
}
