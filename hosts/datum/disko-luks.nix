# DRAFT, not imported anywhere. Layout for reinstalling datum on the
# Spectre x360 15-ch (1 TB NVMe) with the btrfs pool inside LUKS. See
# ~/Projects/manage/laptop-swap.md, phase 5.
#
# At install time this replaces disko-config.nix: copy it over that file
# (keeping the import in default.nix as it is), then run disko against it.
# Applying it to the current, unencrypted install would generate
# fileSystems that point at a LUKS mapping which doesn't exist, and the
# machine wouldn't boot.
#
# Differences from disko-config.nix:
# - The btrfs pool sits inside a LUKS2 container named "crypted"; disko
#   also emits the matching boot.initrd.luks.devices entry.
# - The 1M EF02 partition is gone: it only served GRUB on BIOS boot, and
#   datum boots with systemd-boot on UEFI.
# Subvolumes, labels and mount options are unchanged, so /mnt/btrfs-root
# (by-label/main in filesystems.nix) and btrbk keep working.
#
# Unlocking: disko prompts for a passphrase when it formats the disk.
# That stays the boot-time unlock. A TPM2 keyslot can be added later with
# systemd-cryptenroll without reformatting; that also needs
# boot.initrd.systemd.enable, and is only meaningful with Secure Boot
# (lanzaboote) on, so it's a separate decision (CLAUDE.md, Hardware).
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
