# modules/nixos/monitoring.nix
#
# datum as a Prometheus scrape target. The server side (Prometheus +
# Grafana) runs on `management` (CT 103 on the Proxmox cluster; called
# `management-srv` in older notes, before the names were simplified),
# set up imperatively and out of scope for this repo; notes in
# ~/Projects/manage/homelab-log.md.
{config, ...}: let
  port = config.services.prometheus.exporters.node.port; # 9100

  # management: Prometheus scrapes `datum:9100` from here, over the home
  # LAN. It is not on the tailnet. Its address has changed before (.182
  # in the homelab log, .46 since at least 2026-11-24): if Grafana shows
  # datum down again, compare `getent hosts management` with this, and
  # look for "refused connection ... DPT=9100" in `journalctl -k`.
  scraper = "192.168.5.46";
in {
  services.prometheus.exporters.node = {
    enable = true;
    # Not open to whole networks: datum is a laptop on Wi-Fi, and an open
    # 9100 would be exposed on any network it joins. Over the tailnet it
    # is reachable anyway (tailscale0 is trusted in networking.nix).
    openFirewall = false;
  };

  # ...and from the scraper on the LAN, on Wi-Fi only. The firewall is the
  # iptables one (networking.nftables is off); nixos-fw is rebuilt from
  # scratch on every firewall start, so appending here is safe.
  #
  # 2026-11-22 (6cacb9b) closed 9100 to the tailnet only, assuming the
  # scrape came over Tailscale. It didn't, and datum was down in
  # Prometheus from then until this rule (2026-11-26).
  #
  # Away from home a host at this address could reach node_exporter;
  # that's read-only metrics on a private range, accepted.
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -i wlp59s0 -p tcp -s ${scraper} --dport ${toString port} -j nixos-fw-accept
  '';
}
