# ~/Projects/datum-config/backups.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Where the backup service mounts the share for its own use. Deliberately
  # NOT /mnt/5CDbackup: that path carries an x-systemd.automount direct mount
  # (filesystems.nix), and mounting over a live autofs mountpoint is a mess.
  # Keeping them separate leaves /mnt/5CDbackup untouched for interactive
  # browsing while the service manages its own mount lifecycle.
  shareMnt = "/run/backup-share";
  sharePath = "n/datum";

  # Tried in order; first one answering on 445 wins.
  #
  # 5cd-rack.local is mDNS (avahi + nsswitch mdns4_minimal), so it survives
  # the server's DHCP lease changing -- no hard-coded LAN address to rot.
  # Note the implicit dependency: avahi is enabled in printing.nix, not here.
  #
  # The Tailscale entry is the literal address, NOT the MagicDNS name
  # 5cd-rack.taildad098.ts.net -- MagicDNS resolves via 100.100.100.100,
  # which needs tailscaled up, and tailscaled being down is exactly the case
  # this fallback exists to survive.
  shareHosts = ["5cd-rack.local" "100.76.108.83"];

  # How long to keep retrying before giving up and alerting.
  mountDeadlineSecs = 300;

  # Single source of truth for the CIFS options: reuse the ones declared on
  # /mnt/5CDbackup, minus the pseudo-options that are directives to systemd's
  # fstab generator rather than arguments mount(8) understands.
  cifsOpts = lib.concatStringsSep "," (
    lib.filter (
      o:
        !(lib.hasPrefix "x-systemd." o)
        && !(builtins.elem o ["noauto" "nofail" "_netdev"])
    )
    config.fileSystems."/mnt/5CDbackup".options
  );
in {
  # ======================================================================
  # 1. LOCAL BTRFS AUTOMATED SNAPSHOT MATRIX (BTRBK)
  # ======================================================================
  services.btrbk = {
    instances.local = {
      onCalendar = "hourly";
      settings = {
        # Active retention logic boundaries
        snapshot_preserve_min = "2d";
        snapshot_preserve = "24h 7d 4w";

        # --- INFRASTRUCTURE AUTOMATION CONTROLS ---
        # Only snapshot when @home's btrfs generation actually moved. NOT
        # "ondemand" -- that means "snapshot only if a target subvolume is
        # reachable", and this instance declares no target at all, so it
        # would never snapshot. Pruning per snapshot_preserve* happens
        # either way.
        snapshot_create = "onchange";
        archive_preserve_min = "latest";
        archive_preserve = "7d 4w";

        # btrbk opens this itself, as User=btrbk (uid 998) -- not via the
        # btrfs-progs-sudo backend. It must therefore live somewhere that
        # user can write; /run is root-owned 0755, so /run/btrbk.lock is
        # EACCES and btrbk exits 3 before doing any work. StateDirectory=
        # gives us /var/lib/btrbk, owned btrbk:btrbk.
        lockfile = "/var/lib/btrbk/btrbk.lock";

        volume."/mnt/btrfs-root" = {
          subvolume = "@home";
          snapshot_dir = ".snapshots/home";
        };
      };
    };
  };

  # The btrbk module builds the unit itself and exposes no onFailure hook, so
  # wire the notifier onto the generated unit by name. Without this a broken
  # btrbk fails silently every hour -- which is exactly how the lockfile
  # EACCES above went unnoticed for 15 days.
  systemd.services.btrbk-local.onFailure = ["status-email-alert@%n.service"];

  # =========================================================================
  # 2. DECLARATIVE ATOMIC BACKUPS (NATIVE SYSTEMD RUSTIC CALL ENGINE)
  # =========================================================================
  systemd.services.rustic-atomic-backup = {
    description = "Atomic Daily Rustic Backup via Btrbk Snapshots";

    # Deliberately NO Requires=mnt-5CDbackup.mount.
    #
    # That hard dependency is what silently skipped the 08-26 and 08-27 runs.
    # The timer is Persistent=true, so a run missed while asleep fires the
    # instant the machine resumes -- in the same second tailscaled logs
    # "time jump detected ... probably wake from sleep" and "all links down;
    # pausing". CIFS then tried the Tailscale address over a dead network,
    # the mount unit failed, and the dependency failure aborted the systemd
    # *job* before the service ever activated. Because the unit never
    # activated, nothing set a failure result: `systemctl show` still reports
    # Result=success and ExecMainStatus=0 for a backup that did not happen.
    # Only the journal and the OnFailure= mail reveal it.
    #
    # The mount is now acquired inside the runner, with a candidate list and
    # a bounded retry, so a transient post-resume network state costs a few
    # seconds instead of a whole day's backup.
    after = ["multi-user.target" "tailscaled.service"];
    onFailure = ["status-email-alert@%n.service"];

    # cifs-utils: mount(8) execs mount.cifs out of PATH for -t cifs, and
    # without it the mount fails with "unknown filesystem type 'cifs'" even
    # though the kernel module is fine. Nothing else here needed adding --
    # the probe re-invokes this script's own interpreter via $BASH rather
    # than depending on a bash package being on PATH.
    path = with pkgs; [coreutils util-linux rustic gnutar gzip cifs-utils];

    serviceConfig = {
      Type = "oneshot";
      User = "root";

      # ENVIRONMENT INJECTION: Maps repository variables directly into the process layout
      Environment = [
        "RUSTIC_REPOSITORY=${shareMnt}/restic-repo"
        "RUSTIC_NON_INTERACTIVE=true"
      ];

      # SECURE ROADMAP: Feeds rustic your secret file path strictly at runtime execution,
      # keeping the plain string out of the world-readable /nix/store directory.
      EnvironmentFile = config.sops.secrets."restic-vault-password".path;

      ExecStart = pkgs.writeShellScript "rustic-atomic-runner" ''
        set -euo pipefail

        # 0. Acquire the backup share ourselves, LAN first, Tailscale second.
        #
        # Each candidate is probed on 445 before mounting, so an unreachable
        # or unresolvable one costs 3 seconds instead of a mount timeout.
        # /dev/tcp is a bash builtin, not a real device, so it needs a bash
        # to run in -- $BASH is this script's own interpreter, which beats
        # putting a bash package on PATH: it cannot drift and adds nothing
        # to the closure.
        #
        # Worth knowing before tuning this: Tailscale already carries this
        # traffic over the local link when both ends are on the same LAN
        # (`tailscale ping 5cd-rack` reports a direct 4ms path, no DERP), so
        # trying the .local name first buys no throughput whatsoever. What it
        # buys is a working mount during the window after resume when
        # tailscaled has not finished reconnecting -- which is the only
        # window in which this service has ever failed.
        mkdir -p ${shareMnt}

        deadline=$(( $(date +%s) + ${toString mountDeadlineSecs} ))

        while ! mountpoint -q ${shareMnt}; do
          for host in ${lib.concatStringsSep " " shareHosts}; do
            if timeout 3 "$BASH" -c "</dev/tcp/$host/445" 2>/dev/null; then
              echo "Share answering at $host; mounting //$host/${sharePath}"
              if mount -t cifs "//$host/${sharePath}" ${shareMnt} -o '${cifsOpts}'; then
                break
              fi
              echo "Mount via $host failed; trying next candidate."
            else
              echo "No answer from $host:445."
            fi
          done

          if mountpoint -q ${shareMnt}; then
            break
          fi

          if [ "$(date +%s)" -ge "$deadline" ]; then
            echo "Error: backup share unreachable via ${lib.concatStringsSep ", " shareHosts} after ${toString mountDeadlineSecs}s."
            exit 1
          fi

          echo "No candidate reachable yet; retrying in 15s."
          sleep 15
        done

        echo "Backup share mounted at ${shareMnt}."

        # 1. Discover the most recent timestamped subvolume folder generated by btrbk
        # Use find + sort to handle unexpected blank states or space chars robustly
        LATEST_SNAP=$(find /mnt/btrfs-root/.snapshots/home/ -maxdepth 1 -type d -name "@home.*" | sort -r | head -n 1)

        if [ -z "$LATEST_SNAP" ]; then
          echo "Error: No btrbk snapshots discovered in pool. Aborting atomic pass."
          exit 1
        fi

        echo "Atomic lock achieved. Binding rustic to static snapshot: $LATEST_SNAP"
        mkdir -p /run/restic-atomic-home
        mount --bind "$LATEST_SNAP" /run/restic-atomic-home

        # 2. Refuse to run unless the repository already exists.
        #
        # This deliberately does NOT auto-init. `rustic init` here is a
        # footgun: if the share mounts but is empty, or points somewhere
        # unexpected, init silently creates a brand-new empty repository,
        # backs up into it, and exits 0 -- reporting success while the real
        # history sits unreachable and nothing fails to alert on. That is
        # exactly how a second repository appeared: the path moved from
        # /mnt/5CDbackup (restic, services.restic.backups) to
        # /mnt/5CDbackup/restic-repo (rustic), and this guard created a fresh
        # repo at the new location rather than complaining.
        #
        # Derive the path from RUSTIC_REPOSITORY instead of repeating the
        # literal, so the check cannot drift away from the repo it guards.
        if [ ! -f "$RUSTIC_REPOSITORY/config" ]; then
          echo "Error: no rustic repository at $RUSTIC_REPOSITORY (no 'config' file)."
          echo "Refusing to auto-initialise -- that would mask a missing, empty or wrong mount."
          echo "If a new repository really is intended, create it deliberately:"
          echo "    sudo rustic -r $RUSTIC_REPOSITORY init"
          exit 1
        fi

        # Administrator profile backup pipeline (rik)
        if [ -d "/run/restic-atomic-home/rik" ]; then
          echo "Syncing profile dataset: rik..."
          rustic backup \
            --as-path=/home/rik \
            --tag="user:rik" \
            --glob="!/run/restic-atomic-home/rik/Downloads" \
            --glob="!/run/restic-atomic-home/rik/.cache" \
            --glob="!/run/restic-atomic-home/rik/Dropbox" \
            /run/restic-atomic-home/rik
        fi

        # Guest profile backup pipeline (guest)
        if [ -d "/run/restic-atomic-home/guest" ]; then
          echo "Syncing profile dataset: guest..."
          rustic backup \
            --as-path=/home/guest \
            --tag="user:guest" \
            --glob="!/run/restic-atomic-home/guest/.cache" \
            /run/restic-atomic-home/guest
        fi

        echo "Backup stream transmission completed successfully."
      '';

      # Post-execution hook, in case rustic fails
      # Runs on every exit path, success or failure, including the deadline
      # abort above (where neither mount exists yet -- hence the guards).
      ExecStopPost = pkgs.writeShellScript "rustic-atomic-cleanup" ''
        echo "Tearing down atomic runtime namespaces..."
        if mountpoint -q /run/restic-atomic-home; then
          umount /run/restic-atomic-home
        fi
        rmdir /run/restic-atomic-home || true

        # Drop the share too, so a stale or half-open CIFS mount cannot be
        # inherited by the next run and mistaken for a healthy one.
        if mountpoint -q ${shareMnt}; then
          umount ${shareMnt}
        fi
        rmdir ${shareMnt} || true
      '';
    };
  };

  # =========================================================================
  # 3. AUTOMATED SYSTEMD BACKUP SCHEDULER TIMER
  # =========================================================================
  systemd.timers.rustic-atomic-backup = {
    description = "Timer for Atomic Daily Rustic Backups";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # ======================================================================
  # 4. PANIX OUTBOUND EMAIL TRANSIT PIPELINE (MSMTP)
  # ======================================================================
  programs.msmtp = {
    enable = true;
    accounts = {
      default = {
        host = "mail.panix.com";
        port = 587;
        tls = true;
        tls_starttls = true;
        auth = true;
        user = "rik";
        # Without this msmtp exits 78 with "envelope-from address is missing"
        # and no mail is ever sent. Must be the authenticated user's real
        # address -- panix rejects an envelope sender that doesn't match.
        from = "rik@panix.com";
        passwordeval = "cat ${config.sops.secrets."panix-smtp-password".path}";
      };
    };
  };
  # =========================================================================
  # 5. GLOBAL SYSTEMD FAILURE EMAIL NOTIFIER
  # Automatically triggers on service drops and dispatches status via msmtp
  # =========================================================================
  systemd.services."status-email-alert@" = {
    description = "Status Email Alert Handler for %i";
    path = with pkgs; [coreutils systemd msmtp];
    serviceConfig = {
      Type = "oneshot";
      User = "root"; # Runs as root to read systemd logs securely
      # %i is passed as argv[1], NOT interpolated into the script body.
      # systemd expands specifiers only in the unit file's ExecStart= line;
      # inside the script writeShellScript points at, "%i" stays literal
      # (journalctl rejected it: Invalid unit name "%i" escaped as "\x25i").
      # Use %i and never %I here -- %I would unescape the dashes in a name
      # like rustic-atomic-backup.service into slashes.
      ExecStart = "${pkgs.writeShellScript "systemd-email-alert" ''
        set -euo pipefail

        UNIT="$1"

        # Get the logs for the service that failed
        SERVICE_LOGS=$(journalctl -u "$UNIT" -n 50 --no-pager)

        # Construct a clean email payload
        # Note: msmtp looks for a blank line after headers to identify the message body
        cat <<EOF | msmtp --account=default rik@panix.com
        From: datum systemd <rik@panix.com>
        To: rik@panix.com
        Subject: [SYSTEMD ALERT] $UNIT has FAILED on datum-laptop

        The systemd service unit "$UNIT" has entered a failed state.

        -----------------------------------------------------------------
        LAST 50 LOG ENTRIES FROM JOURNAL:
        -----------------------------------------------------------------
        $SERVICE_LOGS
        EOF
        echo "Alert dispatch completed for failure event instance: $UNIT"
      ''} %i";
    };
  };
}
