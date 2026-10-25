# modules/nixos/desktop/driftwm.nix
#
# driftwm (github:malbiruk/driftwm): a smithay-based, trackpad-first Wayland
# compositor where windows sit on an infinite canvas and the screen is a
# camera over it. Added as a third selectable session next to COSMIC and
# Umbriel, on trial; nothing else changes. cosmic-greeter discovers it via
# services.displayManager.sessionPackages (set by the upstream module), so
# login, lock and pam_gaze (facial-auth.nix) are untouched.
#
# The upstream module also brings, all as mkDefault:
# - xwayland-satellite (driftwm spawns it at startup for X11 apps);
# - xdg-desktop-portal-gtk + -wlr, with driftwm-portals.conf choosing between
#   them. That file is only read when XDG_CURRENT_DESKTOP=driftwm, so the
#   COSMIC and Umbriel sessions keep their own portals;
# - gnome-keyring, which COSMIC already enables. Its SSH agent stays off
#   (services.gnome.gcr-ssh-agent in onepassword.nix), so 1Password keeps
#   SSH_AUTH_SOCK;
# - a `swaylock` PAM service, unused: locking goes through Noctalia (the
#   `login` PAM service, with Gaze), bound in assets/<user>/driftwm.toml.
#
# Per-user config (config.toml) is Home Manager's job:
# home/modules/desktop-integration/driftwm.nix, with each user's
# assets/<user>/driftwm.toml.
{inputs, ...}: {
  imports = [inputs.driftwm.nixosModules.default];

  programs.driftwm.enable = true;
}
