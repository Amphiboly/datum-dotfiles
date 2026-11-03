# modules/nixos/ntfy-alerts.nix
#
# Phone push for failed units, via the self-hosted ntfy server on the
# Proxmox node (set up from nostrum), published behind the nginx proxy as
# ntfy.gb.reubrik.net. The phone is Android, so the app holds its own
# connection to the server and no upstream relay through ntfy.sh is needed.
#
# This runs NEXT TO status-email-alert@ (backups.nix), not instead of it.
# Units list both in onFailure and each notifier is its own oneshot, so the
# mail is the fallback without any "if the POST failed" logic: it goes out
# every time, with the full 50-line log. When pve is down (and ntfy with
# it), this unit fails and the mail still arrives. The push is the short
# version: unit name and the last few log lines.
#
# Reach: ntfy.gb.reubrik.net resolves to the proxy's LAN address
# (192.168.5.44). datum doesn't accept Tailscale subnet routes (RouteAll is
# off), so away from home the POST fails and only the mail gets through.
#
# Auth: the publish token (from 1Password) is the sops secret
# "ntfy-publish-token" (secrets.nix), holding just the token.
{
  config,
  pkgs,
  ...
}: let
  url = "https://ntfy.gb.reubrik.net/homelab-alerts";
  tokenFile = config.sops.secrets."ntfy-publish-token".path;
in {
  systemd.services."status-ntfy-alert@" = {
    description = "Status ntfy Alert Handler for %i";
    path = with pkgs; [coreutils systemd curl];
    serviceConfig = {
      Type = "oneshot";
      User = "root"; # to read the failed unit's journal and the token
      # Same %i-as-argv[1] arrangement as status-email-alert@: specifiers
      # aren't expanded inside the script, and %I would turn the dashes in
      # rustic-atomic-backup.service into slashes.
      ExecStart = "${pkgs.writeShellScript "systemd-ntfy-alert" ''
        set -euo pipefail

        UNIT="$1"

        # One topic for the whole homelab, so units are told apart by tags
        # and priority instead. ntfy priorities: 4-5 sound loudly on the
        # phone, 3 is a normal notification. A failed backup is loud; a
        # failed nightly build only means no new generation tonight, and
        # the nightly mail covers it, so it stays quiet.
        case "$UNIT" in
          btrbk-local.service | rustic-atomic-backup.service)
            PRIORITY=4 TAGS=rotating_light,datum,backup ;;
          nixos-nightly-upgrade.service)
            PRIORITY=3 TAGS=warning,datum,build ;;
          *) PRIORITY=4 TAGS=warning,datum ;;
        esac

        # The header goes in through a process substitution, not -H on the
        # command line, so the token never shows up in /proc/*/cmdline.
        # printf is a bash builtin, so no process sees it either.
        TOKEN=$(< ${tokenFile})

        # Short: it has to read on a lock screen. The mail has the long log.
        journalctl -u "$UNIT" -n 10 --no-pager -o cat \
          | curl -fsS --max-time 15 --retry 3 \
              -H @<(printf 'Authorization: Bearer %s\n' "$TOKEN") \
              -H "Title: $UNIT failed on datum" \
              -H "Priority: $PRIORITY" \
              -H "Tags: $TAGS" \
              --data-binary @- \
              "${url}"
        echo "ntfy alert sent for $UNIT (priority $PRIORITY)"
      ''} %i";
    };
  };
}
