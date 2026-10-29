# flake.nix
{
  description = "Modern Wayland NixOS Flake for HP Spectre Kaby Lake R";

  inputs = {
    #   nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    # TEMPORARY: mcp-nixos only (home/modules/unix-tools/claude-code.nix).
    # nixos-unstable 3ec636362e18 (2026-10-25) carries python `mcp` 2.x, and
    # fastmcp-slim 3.4.7 marks itself broken against mcp >= 2, which takes
    # mcp-nixos down with it. This is the last channel release that built it;
    # being a releases.nixos.org URL it's fixed, so `nix flake update` won't
    # move it. Drop this input (and the reference in claude-code.nix) once
    # NixOS/nixpkgs#563493 (fastmcp -> 4.x) reaches nixos-unstable.
    nixpkgs-mcp.url = "https://releases.nixos.org/nixos/unstable/nixos-26.11pre1097682.02c087f3fe67/nixexprs.tar.zst";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Secure Boot (modules/nixos/secure-boot.nix). Pinned to a release tag,
    # as upstream recommends; bump the tag by hand.
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
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
    # Neither follows our nixpkgs, as docs.noctalia.dev/noctalia/getting-
    # started/nixos asks: with their own pinned nixpkgs the derivations match
    # what upstream CI pushes to noctalia.cachix.org and umbriel.cachix.org
    # (both in nix-settings.nix), so updates download instead of compiling.
    # Following ours made every nixpkgs bump -- i.e. most nights -- rebuild
    # both on nostrum.
    #
    # The risk this accepts, and the guard on it: the GPU driver is never
    # bundled -- libglvnd dlopens it from /run/opengl-driver, i.e. the
    # *system's* Mesa -- so a build on an older glibc than ours dies with
    # "eglGetDisplay failed" once Mesa needs newer glibc symbols. That broke
    # the shell on 2026-09-29 (noctalia on glibc 2.42, us on 2.44), and we
    # followed nixpkgs from then until 2026-10-15. Reported upstream as
    # github.com/noctalia-dev/noctalia/issues/4668; their fix (e639a87e,
    # 2026-10-03) checks hourly whether nixos-unstable's glibc differs from
    # their lock and bumps nixpkgs if so, which shrinks the window from a
    # week to about an hour plus CI time. The remaining race (a glibc bump
    # just before our 03:00 nightly) is caught at evaluation: noctalia.nix
    # and umbriel.nix assert that each one's glibc is at least ours, so a
    # stale pin fails the nightly build (flake.lock restored, mail sent)
    # instead of booting into a broken shell.
    #
    # noctalia tracks the `cachix` branch, which only advances to commits
    # upstream CI has built and tested.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    umbriel.url = "github:noctalia-dev/umbriel";
  };

  outputs = {
    nixpkgs,
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
    # Reinstalling datum from scratch, on the same laptop (disk lost or
    # wiped). The firmware keeps its enrolled Secure Boot keys through all
    # of this; turning Secure Boot off doesn't clear them. So with the
    # signing keys restored, nothing needs enrolling again.
    #
    # Needed from 1Password: the sops age key, the LUKS passphrase (disko
    # asks for it) and the TPM PIN. Everything else comes from the age key:
    # it decrypts secrets.yaml, which holds the CIFS credentials and the
    # rustic password.
    #
    #  1. Firmware: Secure Boot off (the NixOS installer isn't signed with
    #     anything this machine trusts). Leave the keys alone; never "Clear
    #     All Secure Boot Keys", which wipes dbx too.
    #  2. Boot the installer, get online, clone this repo, and partition:
    #       nix run github:nix-community/disko -- --mode disko \
    #         hosts/datum/disko-config.nix
    #     That mounts the new system at /mnt.
    #  3. Age key: paste it from 1Password into
    #     /mnt/var/lib/sops/age/keys.txt (root, 0600). Without it the first
    #     activation can't decrypt rik-password-hash and creates rik locked
    #     (users/rik.nix).
    #  4. System state from the nightly backup (backups.nix, tag "system"):
    #     at least /var/lib/sbctl, BEFORE installing: lanzaboote signs the
    #     boot files during nixos-install and fails without the keys.
    #     Decrypt what's needed with
    #       SOPS_AGE_KEY_FILE=/mnt/var/lib/sops/age/keys.txt \
    #         nix shell nixpkgs#sops -c sops -d secrets.yaml
    #     mount //5cd-rack.local/n/datum with the CIFS credentials, then
    #       nix shell nixpkgs#rustic -c rustic -r <share>/restic-repo \
    #         snapshots --filter-tags system
    #       ... restore <id>:/var/lib/sbctl /mnt/var/lib/sbctl
    #     and the same for the other paths in systemStatePaths, each to
    #     its place under /mnt.
    #     No backup? `sbctl create-keys` into /mnt/var/lib/sbctl instead,
    #     and enroll them after step 6 (secure-boot.nix, steps 1-3).
    #  5. nixos-install --flake .#datum, and set root's password when it
    #     asks (not --no-root-passwd; see users/root.nix).
    #  6. Reboot, then Secure Boot on in the firmware. It boots, because the
    #     restored keys signed everything. `sudo sbctl verify` to check.
    #  7. TPM2 + PIN: the LUKS header is new, so enroll again, with Secure
    #     Boot already on (the slot is bound to PCR 7). Command in the
    #     header of hosts/datum/disko-config.nix.
    #  8. /home from rustic (tags user:rik, user:guest), then
    #     `nh os switch .` so Home Manager takes over.
    #
    # A different board, or firmware reset to factory keys, means
    # enrolling again in step 6 whatever the backup holds.
    #
    # Changing a login password: users/default.nix.
    nixosConfigurations.datum = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [./hosts/datum];
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

    packages.${system} = {
      # `nix build .#context-lmtx` -- see pkgs/context-lmtx for what this is
      # and how to update its pin when upstream ships a new ConTeXt.
      context-lmtx = pkgs.callPackage ./pkgs/context-lmtx {};

      # `nix build .#cosmic-ext-applet-cheatsheet` -- see the package file
      # for how to bump its pin.
      cosmic-ext-applet-cheatsheet = pkgs.callPackage ./pkgs/cosmic-ext-applet-cheatsheet {};
    };

    # `nix fmt` / `nix fmt -- --check .` -- reformats the whole tree with
    # alejandra (also nixd's formatter in vim, home/modules/editors/vim.nix).
    formatter.${system} = pkgs.alejandra;
  };
}
