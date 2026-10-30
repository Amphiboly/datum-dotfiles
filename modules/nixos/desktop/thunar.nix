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

  # Thumbnails. Tumbler does images and PDFs by itself; video needs
  # ffmpegthumbnailer.
  services.tumbler.enable = true;

  environment.systemPackages = with pkgs; [
    xarchiver
    ffmpegthumbnailer
  ];
}
