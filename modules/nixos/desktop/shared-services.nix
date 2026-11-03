# modules/nixos/desktop/shared-services.nix
#
# The system services the Umbriel/Noctalia session needs, which a full
# desktop module would otherwise provide. Every one of these used to arrive
# only as a mkDefault from nixpkgs' COSMIC module (traced with
# definitionsWithLocations); they were declared here (2026-10-29, and
# at-spi2/Qt on 2026-11-03) so that removing COSMIC, done 2026-11-03,
# switched nothing off. Other DEs aren't a drop-in either: Plasma brings
# neither gnome-keyring nor gvfs.
#
# Only system-wide pieces belong here. Session pieces (the polkit agent,
# tray applets) run inside one desktop's session and never reach the
# others; for Umbriel the polkit agent is Noctalia's own (`polkit_agent`
# in assets/<user>/noctalia.toml).
{
  lib,
  pkgs,
  ...
}: {
  services = {
    # Battery state for Noctalia and the critical-battery action
    # (PercentageAction/CriticalPowerAction), and the history that
    # KNOWN-ISSUES.md section 1 reads.
    upower.enable = true;

    # Secret Service provider (gnome-keyring over KWallet, 2026-10-27), and
    # the login keyring that /etc/pam.d/login and passwd unlock and
    # re-encrypt (users/default.nix). Its SSH agent stays off
    # (onepassword.nix).
    gnome.gnome-keyring.enable = true;

    # Trash, MTP and smb:// for GUI file managers; also pulls in udisks2.
    gvfs.enable = true;

    # The accessibility bus. GTK apps look for it at startup and log
    # "Couldn't connect to accessibility bus" without it.
    gnome.at-spi2-core.enable = true;
  };

  # Where GTK apps keep their settings (colour scheme, fonts).
  programs.dconf.enable = true;

  # Qt apps (KDE Connect and the like) take their style from qt5ct/qt6ct,
  # whose ~/.config/qt{5,6}ct carry rik's palette.
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };

  xdg.portal = {
    enable = true;
    # umbriel's portals.conf falls back to "gtk" for everything umbriel's
    # portal doesn't implement (FileChooser, Settings, OpenURI, ...), but
    # the umbriel module doesn't install it.
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    # gtk has no Secret portal; gnome-keyring ships one.
    config.umbriel."org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
  };

  # Icon themes GTK apps fall back on; Adwaita also carries a cursor theme.
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    hicolor-icon-theme
  ];

  # Fallback cursor for anything without one set. (The mkDefault/mkAfter
  # dates from COSMIC, which put "Cosmic" first at the same priority.)
  xdg.icons.fallbackCursorThemes = lib.mkDefault (lib.mkAfter ["Adwaita"]);
}
