# modules/nixos/system-environment.nix
#
# Core system-wide environment: variables and tools that do no harm to a
# guest. Merges what used to be split across the root shell-environment.nix,
# configuration.nix, and an inline block in flake.nix.
{pkgs, ...}: {
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # nixpkgs' Chromium/Electron wrappers then run them on native Wayland
    WLR_NO_HARDWARE_CURSORS = "1"; # Fixes invisible cursor rendering inside virtual machines
  };

  environment.systemPackages = with pkgs; [
    bind.dnsutils
    cifs-utils # mount helper binaries required by your windows smb share
    comma
    curl
    git
    home-manager
    rclone
    rustic
    tailscale # client cli companion for your mesh vpn daemon
    v4l-utils # camera debugging; face auth itself comes from facial-auth.nix
    wl-clipboard # native wayland clipboard manager
  ];
}
