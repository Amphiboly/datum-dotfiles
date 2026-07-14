# ~/Projects/datum-config/networking.nix
{
  config,
  pkgs,
  ...
}: {
  # =========================================================================
  # 1. CORE NETWORKING & HOSTNAME IDENTIFIER LAYOUT
  # =========================================================================
  networking = {
    # System host identity mapping (This dynamically satisfies your target names)
    hostName = "datum";
    networkmanager.enable = true;

    # =========================================================================
    # 2. SYSTEM FIREWALL AUTOMATION BLOCK (TAILSCALE ADAPTATION)
    # =========================================================================
    firewall = {
      enable = true;

      # Automatically opens UDP port 41641 to handle wireguard mesh routing paths
      allowedUDPPorts = [41641];

      # Natively trusts Tailscale's virtual network card adapter interface node
      trustedInterfaces = ["tailscale0"];
    };
  };

  # =========================================================================
  # 3. TAILSCALE MESH VPN DAEMON INTEGRATION SERVICE
  # =========================================================================
  services.tailscale = {
    enable = true;

    # Ensures the daemon prioritizes sub-network routing lanes on your physical desk
    useRoutingFeatures = "client";
  };
}
