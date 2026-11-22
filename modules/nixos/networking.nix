# modules/nixos/networking.nix
#
# Merges what used to be split (and partly duplicated) across the root
# networking.nix and configuration.nix into one definition.
_: {
  networking = {
    hostName = "datum";
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowPing = true; # Retained safely for local network diagnostics

      # Services only rik uses are reached over the tailnet, not opened on
      # whatever network datum is on (2026-11-22). tailscale0 is trusted
      # (every port open to the tailnet), so nothing needs listing for it:
      # SSH (ssh.nix) and the node exporter (monitoring.nix) set
      # openFirewall = false and are reachable there only. What stays open
      # everywhere is what works on the local network by design: mDNS
      # (Avahi also opens 5353 itself) and KDE Connect's 1714-1764, which
      # programs.kdeconnect adds.
      allowedUDPPorts = [
        41641 # Tailscale WireGuard; lets peers connect directly, not via DERP
        5353 # mDNS (Avahi/Bonjour local service discovery)
      ];

      trustedInterfaces = ["tailscale0"];

      # Log refused TCP connections (SYNs only, so it stays quiet) to the
      # kernel log. Off by default in current nixpkgs. This is how to find
      # out that something needed a port closed here:
      #   journalctl -k | grep 'refused connection'
      logRefusedConnections = true;
    };
  };

  # TAILSCALE MESH VPN DAEMON INTEGRATION SERVICE
  services.tailscale = {
    enable = true;

    # Ensures the daemon prioritizes sub-network routing lanes on your physical desk
    useRoutingFeatures = "client";
  };
}
