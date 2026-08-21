# hosts/datum/default.nix
#
# The complete module composition for this one machine (i7-7500U laptop).
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

    # Disko & Lanzaboote
    inputs.disko.nixosModules.disko
    ./disko-config.nix
    inputs.lanzaboote.nixosModules.lanzaboote

    # Sops Secrets
    inputs.sops-nix.nixosModules.sops

    # Core system modules
    ../../modules/nixos/secrets.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/bluetooth.nix
    ../../modules/nixos/backups.nix
    ../../modules/nixos/filesystems.nix
    ../../modules/nixos/printing.nix
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/nix-settings.nix
    ../../modules/nixos/power-management.nix
    ../../modules/nixos/pipewire.nix
    ../../modules/nixos/session-daemons.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/kdeconnect.nix
    ../../modules/nixos/remote-desktop.nix
    ../../modules/nixos/dropbox-sync.nix
    ../../modules/nixos/system-environment.nix
    ../../modules/nixos/fastfetch.nix

    # Users
    ../../modules/nixos/users/default.nix
    ../../modules/nixos/users/root.nix
    ../../modules/nixos/users/rik.nix
    ../../modules/nixos/users/guest.nix

    # Desktop environment — choose one:
    # ../../modules/nixos/desktop/gnome.nix
    ../../modules/nixos/desktop/cosmic.nix

    # Home Manager: system-managed activation (requires a full rebuild).
    # For rebuild-free per-user switches, see flake.nix's homeConfigurations.
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [inputs.nur.overlays.default];

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
