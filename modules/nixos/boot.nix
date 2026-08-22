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

    # HARDWARE DRIVER PATCHES (HYBRID CAMERA QUIRKS)
    extraModprobeConfig = ''
      # 0x100: Ignore frame payload format mismatches on HP/SPC hybrid modules
      # 0x2: Trust the hardware stream timestamps explicitly
      options uvcvideo quirks=0x102
    '';
  };

  time.timeZone = "America/New_York";
}
