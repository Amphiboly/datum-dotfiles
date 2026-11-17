# modules/nixos/desktop/luciole.nix
#
# Luciole (github.com/noctalia-dev/luciole), the Noctalia team's file
# manager, the GUI file manager since 2026-11-16. It went in on trial that
# day next to Strata and replaced it within hours; Nordend was dropped
# from the watch list with it. C++23 drawing straight through Wayland and
# OpenGL ES with Noctalia's own UI library, no Qt or GTK. Grid, list and
# Miller-column views, tabs, split view, previews (images, video, text,
# PDF), archives, Trash with undo, SFTP/SMB/WebDAV through gvfs, used/free
# bars on drives. Released 2026-11-16 as 0.1.0, "in development".
#
# Upstream's NixOS module only puts the package in systemPackages; the
# package is wrapped with its runtime tools (ffmpeg, ffmpegthumbnailer,
# poppler-utils, 7zz, xdg-terminal-exec) and the gvfs/dconf GIO modules.
# System-wide so every user gets it, and so its D-Bus service files land
# in system-path/share/dbus-1, which the session bus searches.
#
# What it provides:
# - Folders: rik's inode/directory default (home xdg.nix).
# - "Show in folder" (org.freedesktop.FileManager1, what browsers and GTK
#   apps call): its dev.noctalia.luciole.FileManager1.service. Nothing
#   else here claims the name since Strata went.
# - Open/Save dialogs: not yet. It ships a FileChooser portal backend,
#   and xdg-desktop-portal-umbriel's packaged umbriel-portals.conf would
#   select it, but shared-services.nix sets xdg.portal.config.umbriel,
#   which generates our own umbriel-portals.conf in its place, and that
#   sends FileChooser to gtk. To switch, add
#   "org.freedesktop.impl.portal.FileChooser" = ["luciole" "gtk"] there.
#
# Thumbnails: Luciole decodes them itself in sandboxed helpers, not
# through tumbler, so the tumbler Excludes for ~/DropboxCloud
# (rclone-dropbox.nix) don't apply, and its "local" thumbnail policy
# takes the rclone FUSE mount for local (it asks GIO, whose remote list
# lacks fuse.rclone). rik's config therefore turns thumbnails off:
# home/modules/desktop-integration/luciole-rik.nix.
#
# Colours: Noctalia has a built-in "luciole" template (renders
# ~/.config/luciole/colors.toml, which Luciole reloads live), added on
# main on 2026-11-16 but not yet on the cachix branch we track. Add it to
# builtin_ids in assets/rik/noctalia.toml once a Noctalia update brings it.
{inputs, ...}: {
  imports = [inputs.luciole.nixosModules.default];

  programs.luciole.enable = true;
}
