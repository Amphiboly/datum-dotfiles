# modules/nixos/boot.nix
{pkgs, ...}: {
  boot = {
    # Forces your architecture to compile and track the absolute latest
    # stable upstream Linux release branch instead of standard LTS lines.
    #kernelPackages = pkgs.linuxKernel.packages.linux_7_1;

    # Alternative option to track whatever the absolute
    # latest stable release is in nixpkgs automatically:
    # kernelPackages = pkgs.linuxPackages_latest;

    # Alternative option to track the optimized cachyos kernel
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

    loader = {
      systemd-boot = {
        enable = true;
        # Let systemd-boot pick a suitable firmware text mode. The glyphs are a
        # fixed firmware bitmap font, so a higher-res mode means more columns:
        # the default ("keep") inherits a low-res mode that truncates entry
        # titles. On this HP "auto" selects mode 3, which fits them. (Mode 3
        # can't be named directly: nixpkgs' enum omits it.)
        consoleMode = "auto";
      };
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["btrfs" "cifs"];

    # No uvcvideo quirks; the 15-ch's built-in camera needs none. (A
    # `quirks=0x102` once lived here for the previous hardware's broken
    # camera and never helped; see commit c2c5199.)
  };

  time.timeZone = "America/New_York";
}
