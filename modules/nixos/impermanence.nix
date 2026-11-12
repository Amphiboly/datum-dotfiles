# modules/nixos/impermanence.nix
#
# What survives a wiped root: the state preserved from /persist by
# nix-community/preservation. The plan, the inventory behind this list and
# the decisions are in IMPERMANENCE-PLAN.md.
#
# This is the only module that knows about /persist. Everything else keeps
# using the standard paths (/var/lib/sops/age/keys.txt, /var/lib/sbctl, ...):
# a bind mount isn't a copy, so the live system reads and writes /persist
# through those paths. /persist is the @persist subvolume, mounted in the
# initrd (hosts/datum/disko-config.nix).
#
# Two switches. `enable` (stage 2, since 2026-11-09) preserves the state
# below from /persist. `wipe` (stage 3) also gives / a fresh, empty @ at
# every boot: an initrd unit moves the old @ to old_roots/ on the btrfs top
# level, where it stays 14 days (see the wipe section at the end). Without
# `wipe`, the mounts just sit on top of the old copies in @.
#
# How preservation works, as far as it matters here (its lib.nix):
# - A bindmount directory gets tmpfiles `d` rules on both sides, which also
#   reset mode and owner of an existing directory. So every entry below
#   states the mode and owner the directory had on 2026-11-09; the
#   defaults (0755 root) would loosen 0700 ones.
# - A bindmount file gets `f` rules and a mount unit that only runs if the
#   file exists in /persist.
# - A symlink gets a tmpfiles `L` rule, which never replaces an existing
#   file. Until the wipe, the symlinked entries (ssh host keys, random-seed)
#   only take effect where the migration replaced the file with a link.
# - inInitrd entries are mounted under /sysroot before stage 2, so they are
#   in place when activation runs: sops decrypts with the age key, and the
#   users script reads the uid/gid map. Their owners must exist in the
#   initrd, which is why only root-owned paths are there.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.datum.impermanence;

  dir = directory: mode: {inherit directory mode;};
  dirOwned = directory: mode: user: {
    inherit directory mode user;
    group = user;
  };

  # Host keys from the openssh module, not by name: 26.11 added an
  # mldsa44-ed25519 key, and a hand-written list missed it (backups.nix had
  # the same problem). Symlinks with configureParent, as preservation's
  # migration guide recommends for ssh keys. A symlink never changes the
  # target's mode, so the private keys keep 0600.
  hostKeyFiles =
    lib.concatMap (k: [
      {
        file = k.path;
        how = "symlink";
        configureParent = true;
      }
      {
        file = "${k.path}.pub";
        how = "symlink";
        configureParent = true;
      }
    ])
    config.services.openssh.hostKeys;

  # The wipe works on the btrfs top level (subvolid=5) of the LUKS mapping
  # disko opens; see hosts/datum/disko-config.nix for both names.
  luksDevice = "/dev/mapper/crypted";
  oldRootsKeepDays = 14;
in {
  options.datum.impermanence = {
    enable =
      lib.mkEnableOption "preserving system state from /persist (IMPERMANENCE-PLAN.md)";
    wipe = lib.mkEnableOption ''
      an empty root (@) at every boot, the previous one kept in old_roots/
      for ${toString oldRootsKeepDays} days. Requires `enable`'';
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Coredumps age out after 2 weeks, as systemd's own tmpfiles rule
      # (systemd.conf: `d /var/lib/systemd/coredump 0755 root root 2w`)
      # intends. preservation writes its own `d` line for every preserved
      # directory, with no age; when two tmpfiles.d files name the same path,
      # systemd-tmpfiles uses the first ("preservation.conf" sorts before
      # "systemd.conf") and logs "Duplicate line ... ignoring" for the other.
      # So from stage 2 (2026-11-09) dumps stopped expiring and piled up in
      # /persist; this puts the age on preservation's line instead. The bind
      # mount means cleaning /var/lib/systemd/coredump cleans the /persist
      # copy. The other duplicates logged at boot (/var/log, /var/lib/lastlog)
      # have no age on either side, so nothing is lost there.
      systemd.tmpfiles.settings.preservation."/var/lib/systemd/coredump".d.age = "2w";

      preservation = {
        enable = true;
        preserveAt."/persist" = {
          directories = [
            # Needed before stage 2 (see the header).
            ((dir "/var/lib/nixos" "0755") // {inInitrd = true;}) # uid/gid map
            ((dir "/var/lib/sops" "0755") // {inInitrd = true;}) # age key; keys.txt itself is 0600

            # Identity and keys.
            (dir "/var/lib/sbctl" "0755") # Secure Boot keys, lanzaboote's pkiBundle
            (dir "/var/lib/tailscale" "0700") # node identity
            (dir "/var/lib/gaze" "0700") # face templates, TPM-sealed key

            # Network and devices.
            (dir "/var/lib/NetworkManager" "0755")
            (dir "/etc/NetworkManager/system-connections" "0700")
            (dir "/var/lib/bluetooth" "0700") # pairings
            (dir "/var/lib/cups" "0755")
            (dirOwned "/var/lib/fwupd" "0755" "fwupd-refresh") # update history

            # systemd. Not all of /var/lib/systemd: catalog and the TPM SRK
            # files are rebuilt at boot. nvpcr is kept because it's unclear
            # whether systemd recreates its NvPCR anchors safely.
            (dir "/var/lib/systemd/timers" "0755") # Persistent= timer stamps
            (dir "/var/lib/systemd/backlight" "0755")
            (dir "/var/lib/systemd/coredump" "0755")
            (dir "/var/lib/systemd/linger" "0755")
            (dirOwned "/var/lib/systemd/timesync" "0755" "systemd-timesync")
            (dir "/var/lib/systemd/nvpcr" "0755")

            # Logs and history.
            (dir "/var/log" "0755") # all of it, journal included
            (dir "/var/lib/upower" "0755") # battery history
            (dir "/var/lib/lastlog" "0755")

            # Caches worth keeping across boots.
            (dir "/var/cache/gaze" "0700") # ML models, 18 MB; re-downloading stalls face login
            (dir "/var/cache/rustic" "0700") # backup repo index (backups.nix)

            # Login screen state (last user, its own cache).
            (dirOwned "/var/lib/noctalia-greeter" "0750" "greeter")
          ];

          files =
            [
              {
                # Read very early; the docs' own special case.
                file = "/etc/machine-id";
                inInitrd = true;
                mode = "0444";
              }
              {
                # Read by systemd-random-seed before local-fs.target; a symlink
                # made in the initrd, as preservation's examples do it.
                file = "/var/lib/systemd/random-seed";
                how = "symlink";
                inInitrd = true;
                configureParent = true;
              }
              {
                # With /var/log kept, logrotate must remember what it rotated.
                file = "/var/lib/logrotate.status";
                mode = "0640";
              }
              {
                # Boot entry naming, tied to machine-id.
                file = "/etc/kernel/entry-token";
                mode = "0644";
              }
            ]
            ++ hostKeyFiles;
        };
      };

      # With machine-id bind-mounted from /persist it's already permanent;
      # this unit would try to commit a transient one and fail. The docs'
      # simple variant.
      systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];
    }

    # --- The wipe (stage 3) -------------------------------------------------
    #
    # In the initrd, after LUKS is open and before / is mounted: mount the
    # btrfs top level, rename @ to old_roots/@-<UTC time>, create an empty @.
    # The nested subvolumes systemd made inside @ (/srv, /var/tmp,
    # /var/lib/machines, /var/lib/portables) move along with it. A rename and
    # a create are metadata operations: milliseconds.
    #
    # NixOS then builds the new root from the store as usual (activation
    # creates /etc, /root with 0700, users and groups), and preservation puts
    # back what /persist holds.
    #
    # If the unit fails, / is mounted anyway (it's ordered before sysroot.mount
    # but nothing requires it): with the old @ if it was never moved, or moved
    # back if creating the new one failed. A failed wipe boots the old root;
    # it never leaves the system without one.
    #
    # Rescue, if a wiped boot is broken: see IMPERMANENCE-PLAN.md (boot a
    # generation with preservation; or from the installer, put
    # old_roots/@-<newest> back as @).
    (lib.mkIf cfg.wipe {
      boot.initrd.systemd.services.impermanence-wipe-root = {
        description = "Move the old root aside and create an empty one";
        wantedBy = ["initrd.target"];
        requires = ["dev-mapper-crypted.device"];
        after = ["dev-mapper-crypted.device"];
        before = ["sysroot.mount"];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        # btrfs-progs, coreutils and mount are in the systemd initrd already
        # (initrdBin, extraBin).
        script = ''
          set -eu
          top=/run/impermanence-btrfs-top
          mkdir -p "$top"
          mount -t btrfs -o subvolid=5 ${luksDevice} "$top"
          trap 'umount "$top"' EXIT

          if [ -e "$top/@" ]; then
            mkdir -p "$top/old_roots"
            old="$top/old_roots/@-$(date -u +%Y%m%dT%H%M%SZ)"
            mv "$top/@" "$old"
            echo "old root moved to ''${old#"$top"/}"
            if ! btrfs subvolume create "$top/@"; then
              mv "$old" "$top/@"
              echo "creating the new root failed; booting the old one" >&2
              exit 1
            fi
          else
            btrfs subvolume create "$top/@"
          fi
        '';
      };

      # Deletes old roots after ${toString oldRootsKeepDays} days, going by the
      # time in the name: the subvolume's own mtime is that of the old /, which
      # hardly ever changes. The three newest are always kept, so a machine
      # left off for weeks still has its last roots to look at. Recursive,
      # because of the nested subvolumes. Runs from the booted system through
      # /mnt/btrfs-root (filesystems.nix), never from the initrd, so boot
      # never waits for btrfs to clean up.
      systemd.services.impermanence-old-roots-cleanup = {
        description = "Delete old roots older than ${toString oldRootsKeepDays} days";
        unitConfig.RequiresMountsFor = "/mnt/btrfs-root";
        serviceConfig.Type = "oneshot";
        path = [pkgs.btrfs-progs pkgs.coreutils pkgs.findutils];
        script = ''
          set -eu
          dir=/mnt/btrfs-root/old_roots
          [ -d "$dir" ] || exit 0
          cutoff=$(date -u -d '${toString oldRootsKeepDays} days ago' +%Y%m%dT%H%M%SZ)
          # Names sort by time; skip the three newest.
          mapfile -t roots < <(find "$dir" -mindepth 1 -maxdepth 1 -name '@-*' | sort | head -n -3)
          for r in "''${roots[@]}"; do
            ts=''${r##*/@-}
            if [[ $ts < $cutoff ]]; then
              echo "deleting ''${r#/mnt/btrfs-root/}"
              btrfs subvolume delete --recursive "$r"
            fi
          done
        '';
      };
      systemd.timers.impermanence-old-roots-cleanup = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true; # stamps live in /var/lib/systemd/timers, preserved
        };
      };
    })
  ]);
}
