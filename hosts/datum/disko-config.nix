# datum's disk layout: Spectre x360 15-ch, 1 TB NVMe, a btrfs pool
# inside LUKS2. Installed with it 2026-10-12 (laptop-swap.md, phase 5, in
# ~/Projects/manage). disko generates the fileSystems entries and the
# boot.initrd.luks.devices entry from this file.
#
# - ESP: 512M vfat on /boot, holding lanzaboote's signed systemd-boot and
#   stubs (secure-boot.nix). There is no BIOS boot partition.
# - The rest is LUKS2, opened as "crypted" (partlabel disk-main-luks).
#   Keyslot 0 holds the passphrase, keyslot 1 a systemd-cryptenroll
#   recovery key; both are in 1Password. Since 2026-10-13 there is also a
#   TPM2+PIN keyslot bound to PCR 7 (Secure Boot state); the PIN is in
#   1Password too. The initrd asks for the PIN first and falls back to the
#   passphrase (see crypttabExtraOpts below).
# - Inside it, btrfs labelled "main" with @, @home, @nix and @dropbox.
#   /mnt/btrfs-root (by-label/main in filesystems.nix) and btrbk depend on
#   the label and the subvolume names.
#
# Only run disko against this file to reinstall: its destroy/format modes
# wipe the disk. Keyslots change without a reformat: the TPM2 slot was
# added with
#   systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 \
#     --tpm2-with-pin=yes /dev/disk/by-partlabel/disk-main-luks
# and is replaced (new PIN, or after a BIOS/dbx update changes PCR 7 and
# the PIN stops working) by adding --wipe-slot=tpm2 to the same command.
# It relies on the systemd initrd, nixpkgs' default (nothing here sets it),
# and on Secure Boot (secure-boot.nix): without it PCR 7 means little.
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
              settings = {
                allowDiscards = true;
                # tpm2-device=auto: unlock with the TPM2 key (enrolled with
                # a PIN, see the header) and fall back to the passphrase
                # prompt if it is absent, refused or the PIN is wrong.
                #
                # tries=0: keep prompting instead of giving up. The default
                # of 3 counts the TPM2 attempt (even with no TPM2 key
                # enrolled), which left 2 passphrase tries; two typos on
                # 2026-10-13 then dropped the initrd into its locked
                # emergency shell. A wrong PIN costs one try the same way.
                # Unlimited tries at the console give an attacker nothing:
                # each guess costs LUKS2's argon2, and the PIN's own limit is
                # the TPM's lockout.
                crypttabExtraOpts = ["tpm2-device=auto" "tries=0"];
              };
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
