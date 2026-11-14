# modules/nixos/desktop/strata.nix
#
# Strata (github.com/lgse/strata) as the GUI file manager, on trial since
# 2026-11-14 in place of Thunar (thunar.nix, still in the repo, no longer
# imported). Rust + GTK4, with previews for images, camera raw, PDF, audio
# and video, which Thunar lacks. Nordend (github.com/pankaspe/nordend-fm) is
# the one to watch: a better fit (built on Umbriel, follows Noctalia's
# gtk.css by itself) but missing network shares and archives for now.
#
# A system module because the package's D-Bus service has to be on the
# system bus path, the same reason thunar.nix was one. rik's default for
# folders is in home/modules/desktop-integration/xdg.nix.
#
# Known gaps:
# - Theming: Strata ignores the GTK theme and uses its own palettes
#   (Settings -> Appearance). Following Noctalia would take a Noctalia
#   template writing ~/.config/strata/themes/<name>.toml, which Strata
#   re-reads live.
# - Thumbnails: Strata makes them itself in bubblewrap helpers, not through
#   tumbler, so the tumbler Excludes for ~/DropboxCloud
#   (rclone-dropbox.nix) don't cover it. Icons view in a big video folder
#   there (UniFi) reads the files over rclone. The only switch is the
#   global Settings -> Appearance -> Show thumbnails.
# - Mounts that aren't removable or gvfs (/mnt/5CDbackup) don't show
#   under Devices; Nordend lists them.
#
# The Nix build disables Strata's in-app updater and its runtime
# installers (--install-portal etc.): updating the flake input updates it.
# RAR extraction is left out (rarSupport, unfree UnRAR); zip, 7z and tar
# work.
{
  inputs,
  pkgs,
  ...
}: let
  strata = inputs.strata.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  environment.systemPackages = [strata];

  # org.freedesktop.FileManager1: what browsers and GTK apps call for "Show
  # in folder" / "Open file location", rather than the inode/directory
  # default. Thunar provided it until now; nothing else here does.
  services.dbus.packages = [strata.fileManagerService];

  # Strata as everyone's Open/Save dialog: not yet. To try it, uncomment.
  # umbriel's portals.conf sends FileChooser to gtk (shared-services.nix);
  # this puts strata first and keeps gtk as the fallback.
  # xdg.portal = {
  #   extraPortals = [strata.fileChooserPortal];
  #   config.umbriel."org.freedesktop.impl.portal.FileChooser" = ["strata" "gtk"];
  # };
}
