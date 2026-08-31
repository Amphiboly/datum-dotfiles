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
      "https://cosmic.cachix.org"
      # lantian is for the cachyos kernel only
      "https://attic.xuyh0120.win/lantian"
    ];

    # Public keys used to verify downloaded binaries
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ]; # Establish the immutable global public keys needed to verify downloads

    # Secure administrative parameters to ensure smooth transitions
    trusted-users = ["root" "rik"];
  };
}
