# flake.nix
{
  description = "Modern Wayland NixOS Flake for HP Spectre Kaby Lake";

  inputs = {
    #   nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";
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
    # Facial authentication. `follows` is safe here only because the nixpkgs
    # above is unstable: gaze is Rust edition 2024, and a stable channel's
    # older rustc breaks partway through its dependency tree.
    gaze = {
      url = "github:GunduLabs/gaze";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nur,
    zen-browser,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    # Instantiated once, correctly (with the NUR overlay applied), and reused
    # by every standalone home-manager output below.
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [nur.overlays.default];
    };
  in {
    nixosConfigurations.datum = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/datum
      ];
    };

    # Standalone per-user configs: `home-manager switch --flake .#<user>`
    # applies without sudo or a system rebuild, for users (like guest) who
    # shouldn't need wheel access just to tweak their own home config.
    homeConfigurations = let
      mkHome = homeModule:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            osConfig = null; # only set when integrated via nixosModules.home-manager
          };
          modules = [
            inputs.sops-nix.homeManagerModules.sops
            {systemd.user.startServices = "sd-switch";}
            homeModule
          ];
        };
    in {
      rik = mkHome ./home.nix;
      guest = mkHome ./home-guest.nix;
    };

    # `nix build .#context-lmtx` -- see pkgs/context-lmtx for what this is
    # and how to update its pin when upstream ships a new ConTeXt.
    packages.${system}.context-lmtx = pkgs.callPackage ./pkgs/context-lmtx {};
  };
}
