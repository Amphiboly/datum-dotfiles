# home/modules/desktop-integration/noctalia.nix
#
# Noctalia (github:noctalia-dev/noctalia): the desktop shell (bar, launcher,
# control center, notifications, lock screen, wallpaper) that pairs with the
# Umbriel compositor enabled in modules/nixos/desktop/umbriel.nix. This is
# the shared half -- enable/systemd/package, identical for every user -- so
# any user who imports it plus a noctalia-<user>.nix companion (which
# supplies `settings` from assets/<user>/noctalia.toml) gets a working shell
# when they pick "Umbriel" at cosmic-greeter, not a bare compositor. See
# home.nix + noctalia-rik.nix and home-guest.nix + noctalia-guest.nix.
#
# This is per-user rather than system-wide, matching this repo's split
# between system privileges and Home Manager config -- Noctalia starts via
# this systemd user service; whether it also fires under COSMIC (not just
# Umbriel) is unverified, see the systemd unit's WantedBy target.
{
  inputs,
  pkgs,
  ...
}: {
  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    # home-manager's own programs.noctalia module (added 2026-08) defaults
    # `package` to `pkgs.noctalia`. That name doesn't exist in plain
    # nixpkgs -- it only appears if something adds it via overlay -- and an
    # overlay build (`final.callPackage ./nix/package.nix {}`, see
    # noctalia's flake.nix) compiles against *our* stacked pkgs (NUR +
    # whatever else). Pointing straight at the flake's own
    # `packages.default` instead builds against plain nixpkgs -- ours,
    # since flake.nix makes the noctalia input follow it (see the comment
    # there for why that matters: the GPU driver comes from the system, so
    # noctalia's glibc must keep up with ours). It's compiled locally;
    # noctalia.cachix.org can't hit with that override. Keep hosts/datum's
    # nixpkgs.overlays free of noctalia's overlay -- reintroducing it would
    # just leave a second, differently built `pkgs.noctalia` sitting there
    # for someone to reach for by accident.
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
