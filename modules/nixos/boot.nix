# modules/nixos/boot.nix
{pkgs, ...}: {
  boot = {
    # Forces your architecture to compile and track the absolute latest
    # stable upstream Linux release branch instead of standard LTS lines.
    kernelPackages = pkgs.linuxKernel.packages.linux_7_1;

    # Alternative option if you just want to track whatever the absolute
    # latest stable release is in nixpkgs automatically:
    # kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["btrfs" "cifs"];

    # No uvcvideo quirks. A previous `options uvcvideo quirks=0x102` lived here
    # to coax more modes out of what presents itself as an SPCA2085 webcam; it
    # never could, for two reasons. 0x102 is PROBE_DEF|PROBE_MINMAX, which only
    # alters stream *probe* negotiation, and the kernel logs "Forcing device
    # quirks ... for testing purpose" on every boot when it is set. More to the
    # point, the fault is below the driver entirely: the camera module is
    # enumerating under the wrong USB identity. A modprobe option cannot change
    # a device's VID:PID. See modules/nixos/facial-auth.nix for the details.
  };

  time.timeZone = "America/New_York";
}
