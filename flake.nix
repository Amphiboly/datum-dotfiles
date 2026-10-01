# flake.nix
{
  description = "Modern Wayland NixOS Flake for HP Spectre Kaby Lake";

  inputs = {
    #   nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
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
    # Follows our nixpkgs, against docs.noctalia.dev/noctalia/getting-started/
    # nixos, which says to leave noctalia's inputs alone so the derivation
    # hash matches noctalia.cachix.org. Not following broke the shell on
    # 2026-09-29: the GPU driver is never bundled -- libglvnd dlopens it from
    # /run/opengl-driver, i.e. the *system's* Mesa -- so a noctalia built on
    # an older nixpkgs (glibc 2.42) died with "eglGetDisplay failed" once our
    # nixpkgs moved to glibc 2.44 and Mesa started requiring GLIBC_2.43. That
    # recurs whenever unstable's glibc outruns noctalia's pin, so we compile
    # locally instead; v5 is meson/C++ with no Qt, so it's a small build.
    # Still on the `cachix` branch, which only advances to commits upstream
    # CI has built and tested.
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

    # `nix fmt` / `nix fmt -- --check .` -- reformats the whole tree with
    # alejandra (also used by Helix's LSP config, home/modules/editors/helix.nix).
    formatter.${system} = pkgs.alejandra;
  };
}
