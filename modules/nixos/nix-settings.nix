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

    # Establish the immutable global public keys needed to verify downloads
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
    ];

    # Secure administrative parameters to ensure smooth transitions
    trusted-users = ["root" "rik"];
  };
}
