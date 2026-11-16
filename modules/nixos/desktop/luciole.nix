# modules/nixos/desktop/luciole.nix
#
# Luciole (github.com/noctalia-dev/luciole), the Noctalia team's file
# manager, on trial since 2026-11-16 alongside Strata (strata.nix), which
# stays the default for now. C++23 drawing straight through Wayland and
# OpenGL ES with Noctalia's own UI library, no Qt or GTK. Grid, list and
# Miller-column views, tabs, split view, previews (images, video, text,
# PDF), archives, Trash with undo, SFTP/SMB/WebDAV through gvfs. Released
# the same day as 0.1.0, "in development".
#
# Upstream's NixOS module only puts the package in systemPackages; the
# package is wrapped with its runtime tools (ffmpeg, ffmpegthumbnailer,
# poppler-utils, 7zz, xdg-terminal-exec) and the gvfs/dconf GIO modules.
# System-wide like strata.nix, so every user gets it.
#
# Keeping Strata the default during the trial:
# - "Show in folder" (org.freedesktop.FileManager1): the package ships
#   dev.noctalia.luciole.FileManager1.service. Installed, both it and
#   Strata would claim the name, and the session bus finds Luciole's
#   first (system-path is on XDG_DATA_DIRS, which session.conf's
#   <standard_session_servicedirs/> searches ahead of the
#   services.dbus.packages dirs where Strata's sits). Which duplicate
#   dbus-broker honours isn't worth relying on, so the override below
#   drops Luciole's file. Delete the override to hand the name over.
# - Open/Save dialogs: xdg-desktop-portal-umbriel's packaged
#   umbriel-portals.conf picks Luciole's FileChooser when it's installed,
#   but shared-services.nix sets xdg.portal.config.umbriel, which
#   generates our own umbriel-portals.conf in its place. That one sends
#   FileChooser to gtk, so dialogs don't change. To try Luciole's, set
#   config.umbriel."org.freedesktop.impl.portal.FileChooser" =
#   ["luciole" "gtk"] there and restart xdg-desktop-portal.
# - Folders (inode/directory) still open in Strata (home xdg.nix).
#
# Colours: Noctalia has a built-in "luciole" template (renders
# ~/.config/luciole/colors.toml, which Luciole reloads live), added on
# main on 2026-11-16 but not yet on the cachix branch we track. Add it to
# builtin_ids in assets/rik/noctalia.toml once a Noctalia update brings it.
{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.luciole.nixosModules.default];

  programs.luciole = {
    enable = true;
    package =
      inputs.luciole.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (prev: {
        postInstall =
          (prev.postInstall or "")
          + ''
            rm $out/share/dbus-1/services/dev.noctalia.luciole.FileManager1.service
          '';
      });
  };
}
