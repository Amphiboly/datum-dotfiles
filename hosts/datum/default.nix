# hosts/datum/default.nix
#
# The complete module composition for this one machine (HP Spectre x360
# 15-ch, i7-8550U laptop, since 2026-10-12).
# Cross-machine-reusable capability lives in ../../modules/nixos/; this file
# only decides which of those + hardware modules apply to "datum".
{inputs, ...}: {
  imports = [
    # Hardware & Platform
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix
    ./laptop-configuration.nix

    # Disko
    inputs.disko.nixosModules.disko
    ./disko-config.nix

    # Sops Secrets
    inputs.sops-nix.nixosModules.sops

    # Secure Boot: lanzaboote replaces systemd-boot (see secure-boot.nix)
    inputs.lanzaboote.nixosModules.lanzaboote

    # Gaze (facial authentication): daemon, D-Bus/polkit, PAM wiring
    inputs.gaze.nixosModules.default

    # Core system modules
    ../../modules/nixos/secrets.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/secure-boot.nix
    ../../modules/nixos/firmware.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/bluetooth.nix
    ../../modules/nixos/backups.nix
    ../../modules/nixos/ntfy-alerts.nix
    ../../modules/nixos/filesystems.nix
    ../../modules/nixos/printing.nix
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/nix-settings.nix
    ../../modules/nixos/remote-builder.nix
    ../../modules/nixos/nightly-upgrade.nix
    ../../modules/nixos/power-management.nix
    ../../modules/nixos/pipewire.nix
    ../../modules/nixos/session-daemons.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/facial-auth.nix
    ../../modules/nixos/onepassword.nix
    ../../modules/nixos/kdeconnect.nix
    ../../modules/nixos/remote-desktop.nix
    ../../modules/nixos/dropbox-sync.nix
    ../../modules/nixos/system-environment.nix
    ../../modules/nixos/fastfetch.nix
    ../../modules/nixos/monitoring.nix

    # Users
    ../../modules/nixos/users/default.nix
    ../../modules/nixos/users/root.nix
    ../../modules/nixos/users/rik.nix
    ../../modules/nixos/users/guest.nix

    # Desktop: Umbriel (compositor) + Noctalia (shell, per-user in Home
    # Manager) is the only session, behind noctalia-greeter. COSMIC and
    # cosmic-greeter were the desktop and login screen until 2026-11-03
    # (tag last-cosmic).
    ../../modules/nixos/desktop/noctalia-greeter.nix
    ../../modules/nixos/desktop/umbriel.nix
    ../../modules/nixos/desktop/shared-services.nix
    ../../modules/nixos/desktop/thunar.nix
    ../../modules/nixos/desktop/wallpapers.nix

    # Home Manager: system-managed activation (requires a full rebuild).
    # For rebuild-free per-user switches, see flake.nix's homeConfigurations.
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    inputs.nur.overlays.default
    # Noctalia's and Umbriel's overlays are deliberately NOT applied here --
    # they would build `pkgs.noctalia`/`pkgs.umbriel` against this overlay
    # stack (NUR etc.), which no binary cache matches. Both packages come
    # straight from the flakes instead (noctalia.nix, umbriel.nix).
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {inherit inputs;};
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
      {systemd.user.startServices = "sd-switch";}
    ];
    users = {
      rik = import ../../home.nix;
      guest = import ../../home-guest.nix;
    };
  };
}
