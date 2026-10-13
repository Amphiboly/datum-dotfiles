# datum's disk layout: Spectre x360 15-ch, 1 TB NVMe, a btrfs pool
# inside LUKS2. Installed with it 2026-10-12 (laptop-swap.md, phase 5, in
# ~/Projects/manage). disko generates the fileSystems entries and the
# boot.initrd.luks.devices entry from this file.
#
# - ESP: 512M vfat on /boot, for systemd-boot on UEFI. There is no BIOS
#   boot partition.
# - The rest is LUKS2, opened as "crypted" (partlabel disk-main-luks).
#   Keyslot 0 holds the passphrase, keyslot 1 a systemd-cryptenroll
#   recovery key; both are in 1Password.
# - Inside it, btrfs labelled "main" with @, @home, @nix and @dropbox.
#   /mnt/btrfs-root (by-label/main in filesystems.nix) and btrbk depend on
#   the label and the subvolume names.
#
# Only run disko against this file to reinstall: its destroy/format modes
# wipe the disk. TPM2 unlock would be an extra keyslot added with
# systemd-cryptenroll (no reformat), and needs boot.initrd.systemd.enable;
# it's only worth it with Secure Boot (lanzaboote) on, a separate decision
# (CLAUDE.md, Hardware).
{
  disko.devices = {
    disk.main = {
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
              extraArgs = ["-n" "boot"];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              # TRIM through dm-crypt. Leaks which blocks are free, which
              # is the usual trade for SSD health and speed.
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = ["-f" "-L" "main"];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd:1" "noatime"];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["compress=zstd:1" "noatime"];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd:1" "noatime"];
                  };
                  "@dropbox" = {
                    mountpoint = "/home/rik/Dropbox";
                    mountOptions = ["noatime"];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
