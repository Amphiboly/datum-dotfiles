# modules/nixos/monitoring.nix
#
# Exposes datum as a scrape target for the Prometheus/Grafana stack planned
# for the Proxmox box (192.168.5.10) — that server side is out of scope for
# this repo. Port/IP here are placeholders and will likely need updating
# once the server side is actually stood up.
_: {
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
  };
}
