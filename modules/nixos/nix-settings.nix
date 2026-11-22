# modules/nixos/nix-settings.nix
_: {
  # Disable native GC to avoid conflicts with nh
  nix.gc.automatic = false;

  # Enable nh helper
  programs.nh = {
    enable = true;
    flake = "/home/rik/Projects/datum/datum-config";

    # Optional: Automated periodic garbage collection
    clean = {
      enable = true;
      extraArgs = "--keep-since 4d --keep 3";
    };
  };

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = ["nix-command" "flakes"];

    substituters = [
      "https://cache.nixos.org/"
      # noctalia and umbriel: upstream CI builds (see their inputs in flake.nix)
      "https://noctalia.cachix.org"
      "https://umbriel.cachix.org"
    ];

    # Public keys used to verify downloaded binaries
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw="
    ]; # Establish the immutable global public keys needed to verify downloads

    # trusted-users is left at the NixOS default, root only (2026-11-22;
    # rik was trusted until then). A trusted user can import unsigned store
    # paths and point the daemon at any substituter, which amounts to root
    # without sudo's password, available to anything running as rik.
    # Nothing here needs it: remote builds (remote-builder.nix) are
    # dispatched by the daemon from /etc/nix/machines whoever asks, and the
    # substituters above apply to every user. If something does need it,
    # the daemon says so: "ignoring the client-specified setting ...
    # because it is a restricted setting and you are not a trusted user".
  };
}
