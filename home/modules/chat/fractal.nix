# home/modules/chat/fractal.nix
#
# Fractal, the GNOME (GTK4/libadwaita) Matrix client (trial from
# 2026-11-20, side by side with iamb, iamb.nix).
#
# Login only: Fractal can't register accounts, so create one on the
# homeserver's website first. The session token goes to the Secret
# Service, which gnome-keyring provides here; settings live in GSettings
# (dconf), so there's nothing declarative to put in this file.
#
# Colours: Noctalia's built-in `gtk` template isn't enabled
# (assets/rik/noctalia.toml), so Fractal shows stock libadwaita, light or
# dark per the colour-scheme preference. Enabling that template would
# restyle every GTK app via ~/.config/gtk-4.0/gtk.css, which is a separate
# decision from this trial.
{pkgs, ...}: {
  home.packages = [pkgs.fractal];
}
