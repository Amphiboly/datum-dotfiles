# home/modules/productivity/rclone-dropbox.nix
#
# The whole Dropbox, cloud-only folders included, as an rclone FUSE mount at
# ~/DropboxCloud; files are fetched when opened. Maestral (maestral-service)
# still syncs ~/Dropbox; this is the on-demand view of what it doesn't,
# chiefly /Apps/UniFi Protect Archive. Neither Linux client has online-only
# files. Same unit as nostrum's (2026-10-19), ported 2026-10-29.
#
# One-time setup, at the desktop (OAuth in the browser): `rclone config`,
# new remote named "dropbox", type dropbox. The token lands in
# ~/.config/rclone/rclone.conf and stays out of Nix, since rclone rewrites
# it as it refreshes. Until that file exists the unit doesn't start.
#
# The VFS cache (~/.cache/rclone) is its own btrfs subvolume
# (filesystems.nix), so cached files stay out of btrbk's @home snapshots.
{
  lib,
  pkgs,
  ...
}: let
  mountPoint = "%h/DropboxCloud";
  # rclone execs fusermount3 from PATH; NixOS's setuid copy is only in
  # /run/wrappers/bin, which a user unit's default PATH lacks.
  fusermount = "/run/wrappers/bin/fusermount3";

  # Tumbler sees a FUSE mount as local, so browsing the mount in Thunar
  # would download every file to thumbnail it (the UniFi folder is
  # hundreds of GB of video). Excludes keeps every thumbnailer out of it.
  # The user tumbler.rc replaces the system one, so this is the whole file:
  # the shipped defaults (tumbler 4.20) plus Excludes.
  thumbnailers = {
    JPEGThumbnailer = 3;
    RawThumbnailer = 3;
    PixbufThumbnailer = 2;
    FfmpegThumbnailer = 2;
    GstThumbnailer = 1;
    FontThumbnailer = 1;
    PopplerThumbnailer = 1;
    OdfThumbnailer = 1;
    DesktopThumbnailer = 0;
  };
  tumblerRc =
    lib.concatStrings (lib.mapAttrsToList (name: priority: ''
        [${name}]
        Disabled=false
        Priority=${toString priority}
        Locations=
        Excludes=~/DropboxCloud
        MaxFileSize=0

      '')
      thumbnailers)
    # Off in the shipped file too, but a missing section would fall back to
    # tumbler's built-in defaults; this one fetches movie posters online.
    + ''
      [CoverThumbnailer]
      Disabled=true
    '';
in {
  systemd.user.services.rclone-dropbox = {
    Unit = {
      Description = "rclone FUSE mount of Dropbox at ~/DropboxCloud";
      ConditionPathExists = "%h/.config/rclone/rclone.conf";
    };
    Install.WantedBy = ["default.target"];
    Service = {
      Type = "notify";
      Environment = "PATH=/run/wrappers/bin";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.rclone}/bin/rclone mount dropbox: ${mountPoint}"
        "--vfs-cache-mode full"
        "--vfs-cache-max-size 20G"
        "--vfs-cache-max-age 24h"
      ];
      ExecStop = "${fusermount} -u ${mountPoint}";
      Restart = "on-failure";
      RestartSec = 30;
    };
  };

  xdg.configFile."tumbler/tumbler.rc".text = tumblerRc;
}
