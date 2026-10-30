# modules/nixos/desktop/thunar.nix
#
# Thunar as the GUI file manager, on trial as the replacement for
# cosmic-files (2026-10-29); Nautilus gets compared on nostrum. GTK, so it
# follows the Noctalia theme with the other GTK apps. Trash, phones and
# smb:// come from gvfs (shared-services.nix).
#
# A system module because programs.thunar also brings xfconf, where Thunar
# keeps its settings, and Thunar's D-Bus service. rik's default for folders
# is in home/modules/desktop-integration/xdg.nix.
{pkgs, ...}: {
  programs.thunar = {
    enable = true;
    # Right-click "Extract here" / "Create archive", through xarchiver
    # below. thunar-volman (auto-run on plug-in) is left out: drives
    # already show in the side pane through gvfs/udisks.
    plugins = [pkgs.thunar-archive-plugin];
  };

  # Thumbnails: images, PDFs, video (ffmpegthumbnailer is linked in),
  # fonts, ODF and camera raw, all built into tumbler.
  services.tumbler.enable = true;

  # ...except EPUB. Its thumbnailer comes through libgepub, which links
  # webkitgtk: 176 MiB of browser engine for ebook covers, nothing else
  # here uses it, and Rik doesn't need them in a file manager (2026-10-29).
  # services.tumbler has no `package` option (upstream removed it), so
  # this overlay is the only way to swap the build. The cost: tumbler no
  # longer matches cache.nixos.org and compiles on every tumbler bump, a
  # small C build. The package checks for libgepub at configure time and
  # skips the plugin without it.
  nixpkgs.overlays = [
    (_: prev: {
      tumbler = prev.tumbler.override {libgepub = null;};
    })
  ];

  environment.systemPackages = [pkgs.xarchiver];
}
