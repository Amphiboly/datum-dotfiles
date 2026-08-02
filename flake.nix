{
  description = "Modern Wayland NixOS 26.05 Flake for Kaby Lake Target";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixgl.url = "github:guibou/nixGL";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko.url = "github:nix-community/disko";
    nur.url = "github:nix-community/NUR";
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
    ghostty.url = "github:ghostty-org/ghostty";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
  };

  outputs = {
    self,
    nixpkgs,
    nixgl,
    nixos-hardware,
    disko,
    nur,
    home-manager,
    sops-nix,
    lanzaboote,
    ghostty,
    nixos-cosmic,
    ...
  } @ inputs: let
    sharedModules = [
      nixos-hardware.nixosModules.common-cpu-intel
      nixos-hardware.nixosModules.common-pc-laptop
      nixos-hardware.nixosModules.common-pc-ssd
      disko.nixosModules.disko
      ./disko-config.nix
      sops-nix.nixosModules.sops
      {
        nix.settings = {
          substituters = [
            "https://cache.nixos.org"
            "https://cosmic.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
          ];
        };
      }
      ./shell-environment.nix
      ./configuration.nix
      ./users.nix
      ./desktop.nix
      ./bluetooth.nix
      ./backups.nix
      ./networking.nix
    ];

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
          "w11-cifs-password" = {
            key = "w11-cifs-credentials";
          };
          "rik-password-hash" = {neededForUsers = true;};
        };
      };

      services.displayManager = {
        enable = true;
      };
    };

    sharedHomeManagerModule = {
      config,
      pkgs,
      ...
    }: {
      imports = [home-manager.nixosModules.home-manager];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.sharedModules = [
        {systemd.user.startServices = "sd-switch";}
      ];
      home-manager.users.rik = import ./home.nix;
    };
  in {
    nixosConfigurations = {
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
            ({
              config,
              pkgs,
              ...
            }: {
              sops.age.keyFile = "/var/lib/sops/age/keys.txt";
              environment.sessionVariables = {
                ZED_ALLOW_EMULATED_GPU = "1";
              };
              services.displayManager.sessionPackages = [ pkgs.niri ];
            })
          ];
      };
    };
  };
}
