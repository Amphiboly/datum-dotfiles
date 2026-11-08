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
# that do are wired in their own files: kitty-rik.nix,
# starship.nix, zsh-rik.nix (fzf), zen-rik.nix, assets/rik/umbriel.toml.
# btop, yazi, bat and Thunderbird need nothing: their configs are writable,
# so Noctalia's hooks select the theme themselves. Neither do KDE apps
# (kcolorscheme): Noctalia writes the colours into ~/.config/kdeglobals,
# itself writable, and signals running KDE apps to reload. Claude Code needs the
# theme picked once, by hand, with /theme.
{
  config,
  lib,
  pkgs,
  ...
}: {
  # The asset is parsed and its font replaced by theme.font.gui
  # (theme/fonts.nix), so the GUI font is set in one place next to the
  # terminal font. The asset carries no font_family; if a re-export from
  # Noctalia's settings brings one back, this still wins. A font chosen in
  # Noctalia's own Settings at runtime lands in
  # ~/.local/state/noctalia/settings.toml, which overrides both.
  programs.noctalia.settings =
    lib.recursiveUpdate
    (builtins.fromTOML (builtins.readFile ../../../assets/rik/noctalia.toml))
    {shell.font_family = config.theme.font.gui;};

  # glow: the template renders ~/.config/glow/noctalia.json. Glow 3 doesn't
  # expand ~ or $VARS in a style path from its config file, so the README
  # has the absolute path set through the environment.
  home.sessionVariables.GLOW_STYLE = "${config.xdg.configHome}/glow/noctalia.json";

  # zathura: the template renders noctaliarc next to zathurarc and only
  # runs (requires_path) once ~/.config/zathura exists; its hook then
  # re-sources running instances over D-Bus. zathura loads it only if
  # zathurarc includes it.
  #
  # Qt Widgets apps: the template renders
  # colors/noctalia.conf under both ~/.config/qt5ct and qt6ct, but has no
  # hook to select it, and qt{5,6}ct only use a palette that
  # color_scheme_path names. So both confs are managed here. They're
  # read-only as a result, and the qt5ct/qt6ct GUIs can't save; nothing
  # was set through them anyway. qt.enable and QT_QPA_PLATFORMTHEME come
  # from modules/nixos/desktop/shared-services.nix. Qt apps read the
  # palette at startup, so restart them after a theme change. Kirigami
  # apps such as KDE Connect ignore this palette: their style
  # (qqc2-desktop-style) reads KColorScheme, i.e. kdeglobals, which the
  # kcolorscheme template covers.
  xdg.configFile = let
    qtct = dir: {
      text = ''
        [Appearance]
        color_scheme_path=${config.xdg.configHome}/${dir}/colors/noctalia.conf
        custom_palette=true
        standard_dialogs=xdgdesktopportal
      '';
    };
  in {
    "zathura/zathurarc".text = ''
      include noctaliarc
    '';
    "qt5ct/qt5ct.conf" = qtct "qt5ct";
    "qt6ct/qt6ct.conf" = qtct "qt6ct";
  };

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
