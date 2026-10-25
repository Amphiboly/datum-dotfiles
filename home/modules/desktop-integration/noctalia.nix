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
# this systemd user service, bound to the Umbriel and driftwm sessions (see
# below).
{
  inputs,
  lib,
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
    # `packages.default` instead builds on noctalia's own pinned nixpkgs,
    # the exact derivation upstream CI pushes to noctalia.cachix.org, so it
    # downloads rather than compiles. Keep hosts/datum's nixpkgs.overlays
    # free of noctalia's overlay -- reintroducing it would just leave a
    # second, differently built `pkgs.noctalia` sitting there for someone to
    # reach for by accident.
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  # The shell loads the system's Mesa, so noctalia's glibc must not be older
  # than ours (the 2026-09-29 "eglGetDisplay failed" breakage; see the
  # comment on the noctalia input in flake.nix). A stale upstream pin fails
  # evaluation here, and with it the nightly build, instead of the session.
  assertions = let
    theirGlibc = inputs.noctalia.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.glibc.version;
  in [
    {
      assertion = lib.versionAtLeast theirGlibc pkgs.glibc.version;
      message = ''
        noctalia's pinned nixpkgs has glibc ${theirGlibc}, older than ours
        (${pkgs.glibc.version}); the shell would fail to load the system's
        Mesa ("eglGetDisplay failed"). Wait for upstream to bump its nixpkgs
        (checked hourly), then update the noctalia input again.
      '';
    }
  ];

  # The module hangs the unit off graphical-session.target, which every
  # systemd-aware session reaches -- COSMIC included -- so Noctalia's bar
  # and panels came up on top of COSMIC's own. Umbriel ships
  # umbriel-session.target (BindsTo graphical-session.target, started only
  # by start-umbriel), so binding to that instead confines Noctalia to
  # Umbriel sessions. mkForce because the module sets these as lists, which
  # would otherwise merge with ours rather than replace them; the module has
  # no `systemd.target` option to do this more politely.
  #
  # driftwm has no session target of its own; its driftwm.service (started by
  # driftwm-session) is the equivalent, and it imports WAYLAND_DISPLAY into
  # the user manager before signalling READY, so ordering after it is enough.
  systemd.user.services.noctalia = let
    sessions = ["umbriel-session.target" "driftwm.service"];
  in {
    Unit = {
      After = lib.mkForce sessions;
      PartOf = lib.mkForce sessions;
    };
    Install.WantedBy = lib.mkForce sessions;
  };
}
