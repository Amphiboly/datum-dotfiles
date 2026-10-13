# modules/nixos/secure-boot.nix
#
# Secure Boot with lanzaboote, using our own keys (sbctl). Since the
# 2026-10-12 reinstall the disk is LUKS-encrypted, but the kernel and
# initrd still sit unencrypted on the ESP; without Secure Boot a swapped
# initrd could record the passphrase. Lanzaboote installs signed stubs
# that embed the kernel command line and the kernel/initrd hashes, so the
# firmware only runs our boot chain. See laptop-swap.md step 11 in
# ~/Projects/manage for the reasoning and the TPM2 unlock options, which
# are a separate step.
#
# Order matters on a machine that doesn't have keys yet:
# 1. `sudo sbctl create-keys` (writes /var/lib/sbctl) BEFORE switching to
#    this config; lanzaboote can't sign without them and the bootloader
#    install fails.
# 2. Switch, then `sudo sbctl verify`: everything signed except the
#    kernel-* files, which the stubs verify by hash instead.
# 3. Firmware: put Secure Boot into setup mode, boot, `sudo sbctl
#    enroll-keys --microsoft` (Microsoft's keys keep option ROMs such as
#    the MX150's and signed firmware add-ons working), then turn Secure
#    Boot on.
#
# /var/lib/sbctl is outside the home backups. Losing it isn't fatal:
# turn Secure Boot off in the firmware, create new keys, enroll again.
#
# Keys are created and enrolled by hand, not with lanzaboote's
# autoGenerateKeys/autoEnrollKeys, so each step can be checked first.
{
  lib,
  pkgs,
  ...
}: {
  # sbctl: create, enroll and verify keys; also handy for troubleshooting.
  environment.systemPackages = [pkgs.sbctl];

  # Lanzaboote replaces the systemd-boot module. boot.nix still sets
  # systemd-boot's consoleMode, which lanzaboote's loader.conf inherits by
  # default (boot.lanzaboote.settings), so that block stays there.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
}
