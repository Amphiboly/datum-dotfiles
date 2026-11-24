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
# trouble). Builds still go to nostrum via remote-builder.nix: the daemon
# dispatches them, so rik needn't be a nix trusted user (and hasn't been
# since 2026-11-22). Root only does the final step `nixos-rebuild boot`
# would: register the generation and update the bootloader.
#
# Policy (decided 2026-10-01):
# - Uncommitted changes to tracked files, or a branch other than main:
#   skip the night and send a "skipped" email. Half-done work at bedtime is
#   never mixed into an automatic generation, and the lock commit never
#   lands under a working tree that's mid-edit.
# - Build fails: flake.lock is restored, status-email-alert@ mails the log.
#   (A hold-back for the CachyOS kernel input, for nights its cache lacked
#   the new kernel, lived here briefly; it went with that kernel on
#   2026-10-15. The kernel now comes from nixpkgs and cache.nixos.org.)
# - Success: flake.lock is committed to local main as "flake lock
#   (nightly)", naming the system it produced. Never pushed. A report goes
#   to the same address (decided 2026-10-18: more mail is fine, procmail
#   files it): the inputs that moved, then nvd's package and closure-size
#   diff against the previous boot generation (what tonight added) and,
#   when datum hasn't been rebooted since an earlier staging, against the
#   running system too (everything the next reboot brings).
# - Pinned inputs (added 2026-11-23): `nix flake update` never moves them,
#   so the report ends with a check. Inputs locked to a release tag (any
#   `ref` like v1.2.3 in flake.lock, found automatically) are compared
#   with the repo's latest GitHub release. Temporary nixpkgs pins wait on
#   a PR, listed in prPins below: the report says when that PR has reached
#   nixos-unstable, so the pin can go. Either case adds "pinned inputs
#   need a look" to the subject. A failed GitHub query just says so; this
#   check never fails the run.
#
# Schedule: 03:00, clear of rustic (00:15) and btrbk (hourly, on the hour,
# done in seconds); nostrum's Kopia run (01:00) is long finished. Only on AC
# power -- checked in the script rather than with ConditionACPower, because
# a unit skipped by a Condition never runs, so it can't send the "skipped"
# email. Not Persistent: a missed night is simply skipped, since a 09:00
# catch-up build would compete with the day's work.
{
  config,
  lib,
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

  # Temporary pins that wait on a nixpkgs PR: input name -> PR number.
  # Keep in step with the TEMPORARY comments in flake.nix; the report
  # flags an entry whose input is gone.
  prPins = {
    nixpkgs-mcp = 563493; # fastmcp -> 4.x
  };
  prPinLines = lib.mapAttrsToList (name: pr: "${name} ${toString pr}") prPins;

  toplevel = "${repo}#nixosConfigurations.${config.networking.hostName}.config.system.build.toplevel";

  runner = pkgs.writeShellScript "nixos-nightly-upgrade" ''
    set -euo pipefail

    REPO=${repo}
    # Run as the repo owner. HOME so git finds ~/.gitconfig (identity for
    # the commit) and nix its cache; PATH is inherited from the unit.
    as_user() { runuser -u ${user} -- env HOME=/home/${user} "$@"; }
    git_() { as_user git -C "$REPO" "$@"; }

    # send_mail SUBJECT, body on stdin. msmtp wants a blank line after the
    # headers. A failed send is logged, never fatal: the night's work is
    # already done by the time it's reported.
    send_mail() {
      { printf 'From: datum systemd <%s>\nTo: %s\nSubject: [datum] %s\n\n' \
          "${mailFrom}" "${mailTo}" "$1"
        cat
      } | msmtp --account=default ${mailTo} || echo "warning: mail not sent"
    }

    skip() {
      echo "SKIPPED: $1"
      send_mail "nightly update skipped: $1" <<EOF
    The nightly flake update on datum did not run: $1.
    Nothing was changed. Once the cause is dealt with (for uncommitted
    work: commit or stash), either wait for tomorrow night or run:
    sudo systemctl start nixos-nightly-upgrade.service
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

    # Holds the pieces of the success report.
    report=$(mktemp -d)

    # From here on, any failure before the commit puts flake.lock back.
    committed=0
    on_exit() {
      if [ "$committed" = 0 ] && ! git_ diff --quiet -- flake.lock; then
        echo "Restoring flake.lock"
        git_ checkout -- flake.lock
      fi
      rm -rf "$report"
    }
    trap on_exit EXIT

    echo "== nix flake update"
    # nix lists the moved inputs on stderr. tee keeps them in the journal as
    # well; pipefail still stops the script if nix fails.
    as_user nix flake update --flake "$REPO" 2>&1 | tee "$report/update"

    echo "== build"
    out=$(as_user nix build --no-link --print-out-paths "${toplevel}")
    echo "built: $out"

    # Taken before staging: what the boot profile pointed at until now.
    prev=$(readlink -f /nix/var/nix/profiles/system)
    running=$(readlink -f /run/current-system)

    # nvd already drops colour when stdout isn't a tty; be explicit anyway,
    # since this ends up in mail.
    echo "== changes vs previous boot generation"
    nvd --color never diff "$prev" "$out" 2>&1 | tee "$report/vs-prev" || true
    if [ "$running" != "$prev" ]; then
      echo "== changes vs running system"
      nvd --color never diff "$running" "$out" 2>&1 | tee "$report/vs-running" || true
    fi

    if [ "$prev" = "$out" ]; then
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

    echo "== pinned inputs"
    # Never fatal: called in an || context, and every query has its own
    # fallback line. Sets pins_attention=1 when something can be bumped or
    # dropped.
    pins_attention=0
    check_pins() {
      local lock="$REPO/flake.lock" api=https://api.github.com
      local name repo ref latest pr pr_json state merged sha status
      # Release-tag pins: whatever flake.lock locks to a v<digit> ref.
      while read -r name repo ref; do
        if latest=$(curl -fsS --max-time 30 "$api/repos/$repo/releases/latest" | jq -er .tag_name); then
          if [ "$latest" = "$ref" ]; then
            echo "$name: $ref, the latest release"
          else
            echo "$name: $ref; $latest is out: https://github.com/$repo/releases/tag/$latest"
            pins_attention=1
          fi
        else
          echo "$name: $ref (GitHub query failed)"
        fi
      done < <(jq -r '.nodes | to_entries[]
          | select((.value.original.ref? // "") | test("^v[0-9]"))
          | "\(.key) \(.value.original.owner)/\(.value.original.repo) \(.value.original.ref)"' "$lock")
      # PR-gated pins.
      while read -r name pr; do
        if ! jq -e --arg n "$name" '.nodes.root.inputs[$n]' "$lock" >/dev/null; then
          echo "$name: no longer in flake.lock; remove it from prPins in nightly-upgrade.nix"
          pins_attention=1
          continue
        fi
        if ! pr_json=$(curl -fsS --max-time 30 "$api/repos/NixOS/nixpkgs/pulls/$pr"); then
          echo "$name: waits on NixOS/nixpkgs#$pr (GitHub query failed)"
          continue
        fi
        state=$(jq -r .state <<<"$pr_json")
        merged=$(jq -r '.merged_at // empty' <<<"$pr_json")
        sha=$(jq -r '.merge_commit_sha // empty' <<<"$pr_json")
        if [ -z "$merged" ]; then
          if [ "$state" = closed ]; then
            echo "$name: NixOS/nixpkgs#$pr was closed without merging; find another way out"
            pins_attention=1
          else
            echo "$name: waits on NixOS/nixpkgs#$pr (still open)"
          fi
          continue
        fi
        if ! status=$(curl -fsS --max-time 30 "$api/repos/NixOS/nixpkgs/compare/$sha...nixos-unstable" | jq -er .status); then
          echo "$name: NixOS/nixpkgs#$pr merged $merged (channel check failed)"
          continue
        fi
        case $status in
          ahead | identical)
            echo "$name: NixOS/nixpkgs#$pr is in nixos-unstable; the pin can go"
            pins_attention=1
            ;;
          *) echo "$name: NixOS/nixpkgs#$pr merged $merged, not in nixos-unstable yet" ;;
        esac
      done < <(printf '%s\n' ${lib.escapeShellArgs prPinLines})
    }
    check_pins >"$report/pins" 2>&1 || echo "(pin check stopped partway)" >>"$report/pins"
    cat "$report/pins"

    if [ "$prev" = "$out" ]; then
      subject="nightly update: nothing new"
    else
      subject="nightly update staged for next boot"
    fi
    if [ "$pins_attention" = 1 ]; then
      subject="$subject; pinned inputs need a look"
    fi
    {
      echo "Nightly flake update on datum, $(date '+%F %R')."
      echo
      echo "Built:  $out"
      if [ "$prev" = "$out" ]; then
        echo "Same as the current boot generation; nothing staged."
      else
        echo "Staged as the next boot generation; reboot to use it."
      fi
      if [ "$committed" = 1 ]; then
        echo "Commit: $(git_ log --oneline -1)"
      else
        echo "flake.lock unchanged; nothing committed."
      fi
      echo
      echo "== Inputs updated"
      # Only the "Updated input" stanzas: the header plus its indented
      # old/new lines, minus the narHash query that makes them unreadable.
      # Leaves out "unpacking ..." progress and warnings.
      if grep -q "Updated input" "$report/update"; then
        grep -E "Updated input|^  " "$report/update" | sed -E "s/[?]narHash=[^']*//"
      else
        echo "(none)"
      fi
      echo
      echo "== Changes vs previous boot generation"
      cat "$report/vs-prev"
      if [ -e "$report/vs-running" ]; then
        echo
        echo "== Changes vs running system (not rebooted since an earlier staging)"
        cat "$report/vs-running"
      fi
      echo
      echo "== Pinned inputs"
      cat "$report/pins"
    } | send_mail "$subject"
  '';
in {
  systemd.services.nixos-nightly-upgrade = {
    description = "Nightly flake update, build, and stage for next boot";
    path = [config.nix.package config.systemd.package pkgs.git pkgs.nvd pkgs.coreutils pkgs.util-linux pkgs.msmtp pkgs.gnugrep pkgs.gnused pkgs.curl pkgs.jq];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    onFailure = ["status-email-alert@%n.service" "status-ntfy-alert@%n.service"];
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
