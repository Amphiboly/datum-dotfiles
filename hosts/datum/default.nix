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

    # Gaze (facial authentication): daemon, D-Bus/polkit, PAM wiring
    inputs.gaze.nixosModules.default

    # Core system modules
    ../../modules/nixos/secrets.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/firmware.nix
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

    # Desktop environment. Gnome was a stopgap for when Cosmic's heavy update
    # cadence outran this laptop's rebuild speed; removed since it was never
    # wanted on its own merits. COSMIC remains the default DE and owns the
    # login/lock greeter (cosmic-greeter), which is where facial-auth.nix's
    # pam_gaze wiring lives. Umbriel (Noctalia's compositor) is added
    # alongside it as a selectable session rather than a replacement, so
    # trying it out doesn't touch the greeter or face auth.
    ../../modules/nixos/desktop/cosmic.nix
    ../../modules/nixos/desktop/umbriel.nix

    # Home Manager: system-managed activation (requires a full rebuild).
    # For rebuild-free per-user switches, see flake.nix's homeConfigurations.
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    inputs.nur.overlays.default
    # Noctalia's overlay is deliberately NOT applied here -- it would build
    # `pkgs.noctalia` against this flake's own nixpkgs/overlay stack instead
    # of noctalia's pinned one, missing noctalia.cachix.org. See the comment
    # on `package` in home/modules/desktop-integration/noctalia.nix, which
    # takes the package straight from inputs.noctalia.packages instead.
    inputs.umbriel.overlays.default

    # TEMPORARY: nixpkgs removed the EOL `buildGo125Module` attribute, but
    # sops-nix's own sops-install-secrets package (config.sops.package's
    # default) still asks for it by name via callPackage, so evaluating
    # system.activationScripts.setupSecrets throws "Go 1.25 is end-of-life".
    # Not fixed upstream as of 2026-09-17: github.com/Mic92/sops-nix/issues/983
    # (issue still open; workaround below confirmed by a sops-nix
    # contributor in that thread). Remove once sops-nix points its Go
    # builder at a supported version.
    (_final: prev: {buildGo125Module = prev.buildGoModule;})
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
