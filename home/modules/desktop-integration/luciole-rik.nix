# home/modules/desktop-integration/luciole-rik.nix
#
# rik's base settings for Luciole, the file manager (the program itself is
# system-wide: modules/nixos/desktop/luciole.nix). Luciole reads
# ~/.config/luciole/config.toml as a base and never writes it; GUI changes
# go to settings.toml beside it and win over this file. Valid changes here
# apply to open windows without a restart. Keys: docs/user/configuration.md
# upstream.
#
# Plain xdg.configFile rather than upstream's Home Manager module, which
# would also install a second copy of the package and needs the flake
# input passed into Home Manager.
#
# thumbnail_policy "never": the "local" default treats the rclone FUSE
# mount (~/DropboxCloud, rclone-dropbox.nix) as local and thumbnails the
# UniFi video archive through it, in grid and list views alike. Opening
# one day's folder (81 files, 32 GB) on 2026-11-16 thumbnailed them all
# and added 1.4 GB to the rclone VFS cache. The policy asks GIO for
# filesystem::remote, and glib's list of remote types (nfs, nfs4, cifs,
# smb, smb2, fuse.sshfs) lacks fuse.rclone, although Luciole's own
# listing code counts all FUSE as remote. No per-path exclude either,
# unlike tumbler. Reported as noctalia-dev/luciole#18; back to "local"
# once fixed.
{pkgs, ...}: {
  xdg.configFile."luciole/config.toml".source =
    (pkgs.formats.toml {}).generate "luciole-config.toml" {
      schema_version = 1;
      browser.thumbnail_policy = "never";
    };
}
