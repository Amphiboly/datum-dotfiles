# modules/nixos/desktop/shared-services.nix
#
# The system services the Umbriel/Noctalia session needs, declared here so
# they don't depend on which full desktop sits alongside it. Until
# 2026-10-29 every one of these arrived only as a mkDefault from nixpkgs'
# COSMIC module (traced with definitionsWithLocations), so removing or
# swapping COSMIC would have switched them off silently. Other DEs aren't
# a drop-in either: Plasma brings neither gnome-keyring nor gvfs.
#
# Only system-wide pieces belong here. Session pieces (the polkit agent,
# tray applets) run inside one desktop's session and never reach the
# others; for Umbriel the polkit agent is Noctalia's own (`polkit_agent`
# in assets/<user>/noctalia.toml).
#
# All of this is a no-op while COSMIC is installed: same values, plain
# assignments instead of its mkDefaults.
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
  };

  # Where GTK apps keep their settings (colour scheme, fonts).
  programs.dconf.enable = true;

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

  # Fallback cursor for anything without one set. COSMIC puts "Cosmic"
  # first at the same mkDefault priority; mkAfter keeps Adwaita behind it
  # while COSMIC is here and makes it the fallback once COSMIC is gone.
  xdg.icons.fallbackCursorThemes = lib.mkDefault (lib.mkAfter ["Adwaita"]);
}
