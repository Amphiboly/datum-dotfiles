# home/modules/desktop-integration/noctalia-rik.nix
#
# rik's Noctalia settings, split out from the shared enable/package logic in
# noctalia.nix so guest can carry an independently-editable config instead of
# sharing rik's (see noctalia-guest.nix). Noctalia's own settings UI is still
# the right place for further tweaks; re-export from there and drop the
# result back into assets/rik/noctalia.toml to update this baseline.
#
# The rest wires up the app templates listed in that file's
# [theme.templates], for apps that have no module of their own here. Apps
# that do are wired in their own files: kitty-rik.nix, helix-rik.nix,
# starship.nix, zsh-rik.nix (fzf), zen-rik.nix, assets/rik/umbriel.toml.
# btop, yazi, bat and Thunderbird need nothing: their configs are writable,
# so Noctalia's hooks select the theme themselves. Claude Code needs the
# theme picked once, by hand, with /theme.
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.noctalia.settings = ../../../assets/rik/noctalia.toml;

  # glow: the template renders ~/.config/glow/noctalia.json. Glow 3 doesn't
  # expand ~ or $VARS in a style path from its config file, so the README
  # has the absolute path set through the environment.
  home.sessionVariables.GLOW_STYLE = "${config.xdg.configHome}/glow/noctalia.json";

  # zathura: the template renders noctaliarc next to zathurarc and only
  # runs (requires_path) once ~/.config/zathura exists; its hook then
  # re-sources running instances over D-Bus. zathura loads it only if
  # zathurarc includes it.
  xdg.configFile."zathura/zathurarc".text = ''
    include noctaliarc
  '';

  # LibreOffice: the template's hook packs the colours into an .oxt
  # extension and installs it with unopkg (skipped while LibreOffice runs;
  # close it and re-render the theme). The hook needs python3 and zip,
  # which aren't on the user PATH the service inherits, so the service
  # starts noctalia with them prepended. Hooks run as children of noctalia
  # and inherit its PATH.
  systemd.user.services.noctalia.Service.ExecStart = lib.mkForce (
    toString (pkgs.writeShellScript "noctalia-with-hook-tools" ''
      export PATH=${lib.makeBinPath [pkgs.python3 pkgs.zip]}''${PATH:+:$PATH}
      exec ${lib.getExe config.programs.noctalia.package} "$@"
    '')
  );
}
