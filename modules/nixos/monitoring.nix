# modules/nixos/monitoring.nix
#
# Exposes datum as a scrape target for the Prometheus/Grafana stack planned
# for the Proxmox box (192.168.5.10) — that server side is out of scope for
# this repo. Port/IP here are placeholders and will likely need updating
# once the server side is actually stood up.
_: {
  services.prometheus.exporters.node = {
    enable = true;
    # Scraped over the tailnet (tailscale0 is trusted in networking.nix),
    # so 9100 isn't opened on other networks (2026-11-22). If the
    # Prometheus server ends up scraping over the LAN instead, open 9100
    # on that interface only (networking.firewall.interfaces.<if>), not
    # everywhere.
    openFirewall = false;
  };
}
