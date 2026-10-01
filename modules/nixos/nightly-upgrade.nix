# modules/nixos/nightly-upgrade.nix
#
# Nightly unattended update: at 03:00, update flake.lock, build the system,
# and stage it as the *next boot* generation. Nothing changes in the running
# session -- the 2026-09-29 noctalia breakage happened at switch time, in
# the live session, so this never switches. Reboot to pick it up, or run
# `nh os switch .` by hand.
#
# Split of privileges: everything that touches the repo or evaluates the
# flake runs as rik (who owns the checkout, so no git "dubious ownership"
# trouble, and who is a nix trusted user, so builds still go to nostrum via
# remote-builder.nix). Root only does the final step `nixos-rebuild boot`
# would: register the generation and update the bootloader.
#
# Policy (decided 2026-10-01):
# - Uncommitted changes to tracked files, or a branch other than main:
#   skip the night and send a "skipped" email. Half-done work at bedtime is
#   never mixed into an automatic generation, and the lock commit never
#   lands under a working tree that's mid-edit.
# - Build fails: flake.lock is restored, status-email-alert@ mails the log.
# - Success: flake.lock is committed to local main as "flake lock
#   (nightly)", naming the system it produced. Never pushed.
#
# Schedule: 03:00, clear of rustic (00:15) and btrbk (hourly, on the hour,
# done in seconds); nostrum's Kopia run (01:00) is long finished. Only on AC
# power -- checked in the script rather than with ConditionACPower, because
# a unit skipped by a Condition never runs, so it can't send the "skipped"
# email. Not Persistent: a missed night is simply skipped, since a 09:00
# catch-up build would compete with the day's work.
{
  config,
  pkgs,
  ...
}: let
  repo = "/home/rik/Projects/datum/datum-config";
  user = "rik";
  # Delivered as rik+datum-build@panix.com, which procmail sorts on. The
  # failure alert (status-email-alert@, backups.nix) routes this unit to the
  # same address. Sender stays rik@panix.com: panix rejects a mismatched one.
  mailTo = "datum-build@rik.users.panix.com";
  mailFrom = "rik@panix.com";

  runner = pkgs.writeShellScript "nixos-nightly-upgrade" ''
    set -euo pipefail

    REPO=${repo}
    # Run as the repo owner. HOME so git finds ~/.gitconfig (identity for
    # the commit) and nix its cache; PATH is inherited from the unit.
    as_user() { runuser -u ${user} -- env HOME=/home/${user} "$@"; }
    git_() { as_user git -C "$REPO" "$@"; }

    skip() {
      echo "SKIPPED: $1"
      msmtp --account=default ${mailTo} <<EOF || echo "warning: skip mail not sent"
    From: datum systemd <${mailFrom}>
    To: ${mailTo}
    Subject: [datum] nightly update skipped: $1

    The nightly flake update on datum did not run: $1.
    Nothing was changed. Commit or stash, then either wait for tomorrow
    night or run: sudo systemctl start nixos-nightly-upgrade.service
    EOF
      exit 0
    }

    systemd-ac-power || skip "datum is on battery"

    branch=$(git_ symbolic-ref --short HEAD 2>/dev/null || echo "(detached)")
    [ "$branch" = main ] || skip "repo is on $branch, not main"
    # Untracked files aren't part of a git flake, so only tracked changes
    # count.
    [ -z "$(git_ status --porcelain --untracked-files=no)" ] \
      || skip "uncommitted changes in $REPO"

    # From here on, any failure before the commit puts flake.lock back.
    committed=0
    restore_lock() {
      if [ "$committed" = 0 ] && ! git_ diff --quiet -- flake.lock; then
        echo "Restoring flake.lock"
        git_ checkout -- flake.lock
      fi
    }
    trap restore_lock EXIT

    echo "== nix flake update"
    as_user nix flake update --flake "$REPO"

    echo "== build"
    out=$(as_user nix build --no-link --print-out-paths \
      "$REPO#nixosConfigurations.${config.networking.hostName}.config.system.build.toplevel")
    echo "built: $out"

    echo "== changes vs running system"
    nvd diff /run/current-system "$out" || true

    if [ "$(readlink -f /nix/var/nix/profiles/system)" = "$out" ]; then
      echo "Already the current boot generation; nothing to stage."
    else
      echo "== staging for next boot"
      nix-env --profile /nix/var/nix/profiles/system --set "$out"
      "$out/bin/switch-to-configuration" boot
    fi

    if git_ diff --quiet -- flake.lock; then
      echo "flake.lock unchanged; nothing to commit."
    else
      git_ commit --quiet \
        -m "flake lock (nightly)" \
        -m "Updated, built and staged for next boot by nixos-nightly-upgrade on $(date -I). System: $out" \
        -- flake.lock
      committed=1
      echo "Committed: $(git_ log --oneline -1)"
    fi
  '';
in {
  systemd.services.nixos-nightly-upgrade = {
    description = "Nightly flake update, build, and stage for next boot";
    path = [config.nix.package config.systemd.package pkgs.git pkgs.nvd pkgs.coreutils pkgs.util-linux pkgs.msmtp];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    onFailure = ["status-email-alert@%n.service"];
    # Don't start it as a side effect of `nh os switch` changing the unit.
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = runner;
      # A full rebuild falling back to datum's own CPU can take hours.
      TimeoutStartSec = "4h";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.nixos-nightly-upgrade = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = false;
    };
  };
}
