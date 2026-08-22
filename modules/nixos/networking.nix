# modules/nixos/networking.nix
#
# Merges what used to be split (and partly duplicated) across the root
# networking.nix and configuration.nix into one definition.
{...}: {
  networking = {
    hostName = "datum";
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowPing = true; # Retained safely for local network diagnostics

      allowedTCPPorts = [
        22 # SSH Remote Login Daemon
      ];
      allowedUDPPorts = [
        41641 # Tailscale wireguard mesh routing
        5353 # mDNS (Avahi/Bonjour Local Service Device Discovery)
      ];

      # Natively trusts Tailscale's virtual network card adapter interface node
      trustedInterfaces = ["tailscale0"];

      # -------------------------------------------------------------------------
      # SECURITY LOCAL NETWORK OPTIMIZATION ALTERNATIVE:
      # -------------------------------------------------------------------------
      # If you want SSH and mDNS to drop instantly when you connect to public Wi-Fi,
      # comment out the global ports blocks above, uncomment your local home network
      # adapter interface string here, and let the system handle the context shift:
      #
      # interfaces."wlan0" = {
      #   allowedTCPPorts = [ 22 ];
      #   allowedUDPPorts = [ 5353 ];
      # };
    };
  };

  # TAILSCALE MESH VPN DAEMON INTEGRATION SERVICE
  services.tailscale = {
    enable = true;

    # Ensures the daemon prioritizes sub-network routing lanes on your physical desk
    useRoutingFeatures = "client";
  };
}
