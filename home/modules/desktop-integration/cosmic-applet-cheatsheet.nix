# home/modules/desktop-integration/cosmic-applet-cheatsheet.nix
#
# COSMIC panel applet listing your live keybindings; packaged locally in
# pkgs/cosmic-ext-applet-cheatsheet (not in nixpkgs).
#
# How COSMIC finds applets: cosmic-panel scans XDG_DATA_DIRS for
# share/applications/*.desktop entries carrying X-CosmicApplet=true, and
# offers those under Settings -> Desktop -> Panel -> Applets. So installing
# an applet is just putting its package on that path -- the per-user
# profile (/etc/profiles/per-user/<user>/share) is on it, which is why
# home.packages is enough and no system rebuild is needed. Any nixpkgs
# cosmic-ext-applet-* goes in the same way. Adding it to the panel is then
# a manual step in Settings.
#
# The README's suggested Super+C binding (Spawn
# `cosmic-ext-applet-cheatsheet --window`) is deliberately left to COSMIC
# Settings: custom shortcuts all live in one file,
# ~/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom, and a
# home.file there would be a read-only store symlink that stops Settings
# from saving any shortcut added by hand.
{pkgs, ...}: {
  home.packages = [
    (pkgs.callPackage ../../../pkgs/cosmic-ext-applet-cheatsheet {})
  ];
}
