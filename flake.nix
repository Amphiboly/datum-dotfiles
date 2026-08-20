# flake.nix
{
  description = "Modern Wayland NixOS Flake for HP Spectre Kaby Lake";

  inputs = {
    #   nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    disko,
    home-manager,
    sops-nix,
    lanzaboote,
    nur,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    # Instantiates pkgs with unfree allowed for standalone flake inputs
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      nixpkgs.overlays = [
        nur.overlays.default
      ];
    };
  in {
    nixosConfigurations.datum = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [
        # Hardware & Platform
        nixos-hardware.nixosModules.common-cpu-intel
        nixos-hardware.nixosModules.common-pc-laptop
        nixos-hardware.nixosModules.common-pc-ssd
        ./hardware-configuration.nix
        ./laptop-configuration.nix

        # Disko & Lanzaboote
        disko.nixosModules.disko
        ./disko-config.nix
        lanzaboote.nixosModules.lanzaboote

        # Core Modules
        ./configuration.nix
        ./users.nix
        ./desktop.nix
        ./shell-environment.nix
        ./bluetooth.nix
        ./backups.nix
        ./networking.nix
        # Choose one of the following:
        #./desktop-gnome.nix
        ./desktop-cosmic.nix

        # Sops Secrets
        sops-nix.nixosModules.sops

        # Global Nixpkgs & Environment
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [
            nur.overlays.default
          ];
          environment.sessionVariables = {
            ZED_ALLOW_EMULATED_GPU = "1";
          };
        }

        # Home Manager Module with Rik and Guest
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            extraSpecialArgs = {inherit inputs;};
            sharedModules = [
              sops-nix.homeManagerModules.sops
              {systemd.user.startServices = "sd-switch";}
            ];
            users = {
              rik = import ./home.nix;
              guest = import ./home-guest.nix;
            };
          };
        }
      ];
    };
  };
}
