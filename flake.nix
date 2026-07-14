{
  description = "Modern Wayland NixOS 26.05 Flake for Kaby Lake Target";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixgl.url = "github:guibou/nixGL";
    noctalia.url = "github:noctalia-dev/noctalia";
    ghostty.url = "github:ghostty-org/ghostty";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote/master";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = {
    self,
    nixpkgs,
    nixgl,
    noctalia,
    ghostty,
    home-manager,
    nur,
    disko,
    sops-nix,
    lanzaboote,
    nixos-hardware,
    ...
  } @ inputs: let
    # =========================================================================
    # REUSABLE SHARED MODULE VARIABLES (DRY: Don't Repeat Yourself)
    # =========================================================================
    # 1. Shared core modules array common to both local targets
    sharedModules = [
      ##?? nixos-hardware.nixosModules.common-cpu-intel-kaby-lake-cpu-only
      nixos-hardware.nixosModules.common-cpu-intel
      nixos-hardware.nixosModules.common-pc-laptop
      nixos-hardware.nixosModules.common-pc-ssd
      disko.nixosModules.disko
      ./disko-config.nix
      sops-nix.nixosModules.sops
      ./shell-environment.nix
      ./noctalia-module.nix
      ./configuration.nix
      ./users.nix
      ./desktop.nix
      ./bluetooth.nix
      ./backups.nix
      ./networking.nix
    ];

    # 2. Shared inline software environment module attributes configuration set
    sharedEnvModule = {
      config,
      pkgs,
      ...
    }: {
      nixpkgs.overlays = [
        nixgl.overlay
        nur.overlays.default
        # FIX: Temporarily stubs out the broken cantarell-fonts package to bypass the python3.13 build error
        (final: prev: {
          cantarell-fonts = final.emptyDirectory;
        })
      ];
      nixpkgs.config.allowUnfree = true;

      sops = {
        defaultSopsFile = ./secrets.yaml;
        validateSopsFiles = false;
        secrets = {
          "w11-cifs-password" = {};
          "rik-password-hash" = {neededForUsers = true;};
        };
      };

      environment.systemPackages = [pkgs.fuzzel];

      programs.mangowc.enable = true;
      programs.mangowc.package = pkgs.mango;

      services.displayManager = {
        enable = true;
        #        autoLogin = {
        #          enable = true;
        #          user = "rik";
        #        };
        defaultSession = "mango";
        sessionPackages = [pkgs.mango pkgs.niri];
      };
    };

    # 3. Shared User-Space Home Manager module configuration block
    sharedHomeManagerModule = {
      config,
      pkgs,
      ...
    }: {
      imports = [home-manager.nixosModules.home-manager];

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.sharedModules = [
        {systemd.user.startServices = "sd-switch";}
      ];
      home-manager.users.rik = import ./home.nix;
    };
  in {
    nixosConfigurations = {
      # =========================================================================
      # TARGET 2: High-Performance Bare-Metal Physical Laptop Target Configuration
      # =========================================================================
      datum-laptop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules =
          sharedModules
          ++ [
            {nixpkgs.hostPlatform = "x86_64-linux";}
            lanzaboote.nixosModules.lanzaboote
            ./laptop-configuration.nix # Core Intel VA-API Media offloading modules layer
            ./hardware-configuration.nix # Real laptop hardware component device scan files
            sharedEnvModule
            sharedHomeManagerModule

            # Physical Hardware Unique Overrides Configuration Block
            ({
              config,
              pkgs,
              ...
            }: {
              sops.age.keyFile = "/var/lib/sops/age/keys.txt";

              environment.sessionVariables = {
                ZED_ALLOW_EMULATED_GPU = "1";
              };

              services.displayManager.sessionPackages = [pkgs.mango pkgs.niri];
            })
          ];
      };
    };
  };
}
