# ~/Projects/datum-config/disko-config.nix
{
  # CORE DISK TOPOLOGY CONFIGURATION MATRIX
  disko.devices = {
    disk.vda = {
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # Standard GRUB MBR fallback layout frame
          };
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];

              # FIX: Bakes the 'boot' volume label explicitly into your FAT32 sectors!
              extraArgs = ["-n" "boot"];
            };
          };
          btrfs = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = ["-f" "-L" "main"]; # FIX: Added '-L main' to flag your storage pool name!
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
}
