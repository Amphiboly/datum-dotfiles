# flake.nix
{
  description = "Modern Wayland NixOS Flake for HP Spectre Kaby Lake";

  inputs = {
    #   nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # /release (below) ensures precompiled kernel
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
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
    # Noctalia desktop shell + its Umbriel compositor: an alternative to
    # COSMIC. Umbriel is registered as a selectable session alongside COSMIC
    # (see modules/nixos/desktop/umbriel.nix) rather than replacing it, so
    # cosmic-greeter stays the login/lock PAM service pam_gaze is wired
    # into (facial-auth.nix).
    #
    # Pinned to the `cachix` branch (not `main`) and deliberately NOT
    # following our nixpkgs: per docs.noctalia.dev/noctalia/getting-started/
    # nixos, overriding any of Noctalia's inputs -- inputs.nixpkgs.follows
    # included -- changes the derivation hash and misses noctalia.cachix.org
    # entirely, forcing a from-source Qt/QML rebuild on every change. The
    # `cachix` branch always points at the latest commit CI has actually
    # finished caching, so this pin trades one extra nixpkgs copy (fetched
    # under a different store path from our own) for guaranteed prebuilt
    # binaries. The substituter + key are in modules/nixos/nix-settings.nix.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    umbriel = {
      url = "github:noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nix-cachyos-kernel,
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
        {
          nixpkgs.overlays = [
            nix-cachyos-kernel.overlays.pinned
          ];
        }
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
