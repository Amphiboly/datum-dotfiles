# modules/nixos/system-environment.nix
#
# Core system-wide environment: variables and tools that do no harm to a
# guest. Merges what used to be split across the root shell-environment.nix,
# configuration.nix, and an inline block in flake.nix.
{pkgs, ...}: {
  environment.sessionVariables = {
    ZED_ALLOW_EMULATED_GPU = "1";
    NIXOS_OZONE_HLWM = "1"; # Forces Chromium/Electron apps to use native Wayland
    WLR_NO_HARDWARE_CURSORS = "1"; # Fixes invisible cursor rendering inside virtual machines
  };

  environment.systemPackages = with pkgs; [
    wl-clipboard # native wayland clipboard manager
    curl
    git
    home-manager
    cifs-utils # mount helper binaries required by your windows smb share
    tailscale # client cli companion for your mesh vpn daemon
    rustic
    comma
    v4l-utils # camera debugging; face auth itself comes from facial-auth.nix
  ];
}
