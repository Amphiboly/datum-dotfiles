---
author:
- Claude
- Rik Kabel
title: Impermanence on datum, a plan
date: 2026-11-09
lang: en-US
whitespace: medium
layout: |
  width=middle,backspace=1.5in,cutspace=1.5in, |
  height=middle,topspace=0.75in,bottomspace=0.75in
mainfont: libertinus sans
linesize: 13.5pt
fontsize: 11pt
pagenumbering: location=margin
...

# Goal

Make `@` (mounted at `/`) start empty on every boot. Everything that has to
survive lives on a new `@persist` subvolume and is bind-mounted or symlinked
back into place by nix-community/preservation. `@nix`, `@home` and
`@dropbox` are untouched.

The work goes in four stages, each a separate commit or group of commits.
Stages 1 and 2 change nothing visible. Stage 3 turns on the wipe and is the
only one that needs a rescue plan. Stage 4 is cleanup and backups.

Status of the facts below: the preservation option names, the examples
quoted, and the flake outputs (`nixosModules.default` and
`nixosModules.preservation`, last modified 2026-10-25) were checked against
upstream on 2026-11-08. The Nix snippets themselves are **sketches and have
not been evaluated**. Each is to be validated with `nix eval` / `nix flake
check` as it lands.

# Things found while surveying datum

- **Nested subvolumes inside `@`.** `/var/lib/machines`,
  `/var/lib/portables`, `/var/tmp` and `/srv` are btrfs subvolumes (inode
  256). systemd's tmpfiles creates them with `v`/`q` lines. They move along
  with `@` when it is renamed, and on the fresh root tmpfiles creates them
  again. But deleting an old root has to be recursive, or `btrfs subvolume
  delete` refuses.
- **sops reads keys during activation, before stage-2 mounts exist.**
  `sops.age.keyFile` is `/var/lib/sops/age/keys.txt`. Activation also
  decrypts `rik-password-hash` for the users script. Preservation entries
  without `inInitrd` aren't mounted yet at that point. With openssh
  enabled, sops-nix also defaulted to the ssh host keys as decryption keys
  (ed25519 for age, RSA for gnupg). They were never recipients in
  `.sops.yaml`, so commit d310054 cleared both `sshKeyPaths`. The age key
  file is now the only early dependency.
- **`/root` can be ephemeral.** The nix-daemon's ssh to nostrum uses the
  system-wide `/etc/ssh/ssh_known_hosts` (`programs.ssh.knownHosts`) and a
  sops key (`remote-builder.nix`), so nothing in `/root/.ssh` is needed.
  Still check `/root` with sudo before stage 3.
- **`users.mutableUsers = true` (`users/default.nix`).** That makes
  `/etc/passwd`, `/etc/shadow` and `/etc/group` mutable state. On a wiped
  root, accounts are recreated at every boot from config: rik's password
  from `hashedPasswordFile` (sops), so password changes made with `passwd`
  don't survive. **Resolved 2026-11-09: `mutableUsers = false`**, done
  ahead of stage 1. /etc/shadow can't be carried across: pam_unix
  (`passverify.c`) and shadow-utils (`commonio.c`) both replace it with
  rename(), which fails with EBUSY on a bind mount and silently replaces a
  symlink (so userborn's `passwordFilesLocation` would lose `passwd`
  changes too). rik's and root's passwords are now sops hashes applied at
  every activation, and guest's is a fixed known one.
- **`/var/log` is 600 MB.** That's fine: it is copied with
  `--reflink`, which is instant on the same filesystem.
- **`/var/lib/cosmic-greeter`** is a leftover from before 2026-11-03.
  Don't persist it.
- **`/var/lib/private`** (DynamicUser state) and `/var/lib/gaze` weren't
  readable without root. Inventory them with sudo in stage 0.

# Stage 0: inventory (done 2026-11-09)

A read-only script, run as root, listed the directories rik can't read,
every `/var/lib` and `/var/cache` directory with its size and last change,
the regular (non-symlink) files in `/etc`, the nested subvolumes, and
every file on `@` changed in the last 14 days. What it changed in the
list below:

- **A third ssh host key.** `services.openssh.hostKeys` (by `nix eval`) is
  rsa, ed25519 and **mldsa44-ed25519**. sshd generated the post-quantum
  key on 2026-11-04 (OpenSSH 10.6). It isn't in `systemStatePaths`, so
  it wasn't backed up until the backups.nix fix of 2026-11-09. The ecdsa
  key on disk is stale: it's not in
  `hostKeys`, and sshd doesn't load it. The preserve list now takes the
  keys from `config.services.openssh.hostKeys` (each path plus `.pub`)
  rather than naming them.
- **`/root/.cache/rustic`** is rustic's local cache of the backup repo's
  index and snapshot lists (most of `/root`'s 63 MB; 89 files changed in
  two weeks). Wiped, the first backup after every boot would rebuild it
  over CIFS. Persist it. The rest of `/root` (nix's eval/binary cache,
  `.nix-channels`, an empty `.ssh`, `.bash_history`) can go.
- **`/var/lib/systemd`** is 45 MB, mostly coredumps. Besides timers,
  backlight, coredump and linger: `timesync` (timesyncd's clock floor, cheap)
  and `nvpcr` (systemd's NvPCR anchors; whether systemd re-creates them
  safely is unverified, so keep them). The `tpm2-srk-public-key.*` files
  are rewritten from the TPM at every boot, and `catalog` is rebuilt, so
  both can go.
- **Empty, so not persisted:** `/var/lib/AccountsService`, `udisks2`, `tlp`,
  `misc`, `private`, and `/var/cache/private`, `/var/cache/tailscale`.
  (`tlp` and `AccountsService` were on the draft list.)
- **`/etc` regular files.** Besides machine-id, the ssh keys and
  `NetworkManager/system-connections` (one file, `5CD.nmconnection`),
  everything there is regenerated by activation or its service:
  passwd/group/shadow (immutable users), subuid/subgid (from
  `/var/lib/nixos`), sudoers, fwupd.conf, logrotate.conf, printcap,
  resolv.conf, wpa_supplicant's empty `imperative.conf`, and the
  `.clean`/`.updated`/`NIXOS` markers. One more is kept:
  `/etc/kernel/entry-token` (boot entry naming, tied to machine-id).
- **Nested subvolumes confirmed:** `@/srv`, `@/var/lib/portables`,
  `@/var/lib/machines`, `@/var/tmp`, all empty.
- **`/var/lib/cosmic-greeter`** (3.7 MB, owner uid gone) last changed on
  2026-11-03, the day COSMIC was removed. The first wipe clears it.
- **Small additions:** `/var/lib/logrotate.status` (with `/var/log`
  persisted, logrotate needs to know what it already rotated) and
  `/var/lib/lastlog`.

# The preserve list

Built from `systemStatePaths` in `modules/nixos/backups.nix`, then checked
against the stage 0 inventory.

**In the initrd (`inInitrd = true`)**, needed by activation or early boot:

| Path | How | Why early |
|---|---|---|
| `/etc/machine-id` | bindmount | the docs' own special case |
| `/var/lib/nixos` | bindmount | users/groups script reads the uid/gid map |
| `/var/lib/sops` (0700) | bindmount | sops decrypts during activation |
| `/var/lib/systemd/random-seed` | symlink, `configureParent` | read before local-fs |

**sops** (decided 2026-11-09): `secrets.nix` keeps naming
`/var/lib/sops/age/keys.txt`. The rule behind it is that only
`impermanence.nix` knows about `/persist`, and every other module uses the
standard paths. A bind mount isn't a copy: the live system writes through
it straight to `/persist` either way, so the only thing in question was
which path the config names. The rejected alternative was pointing
`age.keyFile` at `/persist/...` directly.

**Stage 2 (defaults)**:

- Directories:
  - Identity and keys: `/var/lib/sbctl` (lanzaboote `pkiBundle`),
    `/var/lib/tailscale`, `/var/lib/gaze`.
  - Network and devices: `/var/lib/NetworkManager`,
    `/etc/NetworkManager/system-connections` (mode 0700),
    `/var/lib/bluetooth`, `/var/lib/cups`, `/var/lib/fwupd`.
  - systemd: `/var/lib/systemd/{timers,backlight,coredump,linger,timesync,nvpcr}`.
  - Logs and history: `/var/log`, `/var/lib/upower`, `/var/lib/lastlog`.
  - Caches worth keeping: `/var/cache/gaze` (the ML models, 18 MB),
    `/root/.cache/rustic`.
  - Login screen: `/var/lib/noctalia-greeter`.
- Files: the host keys from `config.services.openssh.hostKeys`, each path
  and its `.pub`, as `how = "symlink"; configureParent = true;`, which is
  what upstream's migration page recommends. Also
  `/var/lib/logrotate.status` and `/etc/kernel/entry-token`.
- Deliberately not persisted: the rest of `/root`, `/var/lib/machines`,
  `/var/lib/portables`, `/var/tmp`, `/srv`, `/var/lib/btrbk` (lockfile
  only), `/var/lib/cosmic-greeter`, the empty `/var/lib` directories above,
  `/var/lib/systemd/{catalog,tpm2-srk-public-key.*,ephemeral-trees}`,
  `/var/cache/{cups,fwupd,fwupdmgr,tuigreet}`, the stale ecdsa host key,
  and everything regenerated in `/etc`.

machine-id uses the docs' *simple* variant:
`systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];`.

# Stage 1: the `@persist` subvolume (commit 1)

1. `sudo btrfs subvolume create /mnt/btrfs-root/@persist`
2. Add it to `hosts/datum/disko-config.nix`, so a reinstall gets it:

        "@persist" = {
          mountpoint = "/persist";
          mountOptions = ["compress=zstd:1" "noatime"];
        };

   and, since disko has no knob for it,
   `fileSystems."/persist".neededForBoot = true;`.
   On a running system this only adds a mount. disko doesn't reformat on
   rebuild.
3. `nh os switch .` and check that `/persist` is mounted.

**Lesson from 2026-11-09.** The first attempt switched before `@persist`
existed. nh's first step is `switch-to-configuration test`, which started
the new `persist.mount`. It failed (`fsconfig() failed: No such file or
directory`), and because `local-fs.target` requires every local mount and
has `OnFailure=emergency.target`, the *running* system went into emergency
mode. The session ended, and pipewire and syncthing went down with it.
The failed test activation also meant nh never registered a generation or
updated the boot menu, so nothing persisted; booting the previous entry
recovered fully. The rule: a change that adds a mount must have its device
or subvolume in place before any `switch`. For anything riskier, `nh os
boot` and a reboot fail more gently than a switch.

# Stage 2: preservation, wipe still off (commits 2–3)

1. Flake input `preservation` (github:nix-community/preservation), with no
   `nixpkgs` to follow (it has no inputs that need it). Import
   `inputs.preservation.nixosModules.default` in `hosts/datum/default.nix`.
2. New `modules/nixos/impermanence.nix` holding the preserve list, the sops
   change, and a `datum.impermanence.wipe` option (default `false`) that
   stage 3 flips. That follows CLAUDE.md's `options`/`config` structure,
   and the option makes stage 3's revert a one-line change.
3. **Use `nh os boot .`, not `switch`.** A switch would bind-mount empty
   or freshly copied directories over paths that running services have
   open. And if any new mount fails during a switch, the running system
   drops into emergency mode (see stage 1's note). With `boot`, a failing
   mount only shows up at the reboot, where the previous generation is
   one menu entry away.
4. Right after building and before rebooting, copy the state:

        for p in <each preserved path>; do
          sudo mkdir -p "/persist$(dirname "$p")"
          sudo cp -a --reflink=always "$p" "/persist$p"
        done

   Then reboot immediately so the copies don't go stale.
5. Check after the reboot: `findmnt -R / | grep persist` shows every
   mount. `tailscale status` shows the same node. Wi-Fi and Bluetooth
   pairings are intact. Face login works. `sops` secrets are present in
   `/run/secrets`. `sbctl status` works. And a test `nh os switch .`
   succeeds, which proves lanzaboote can still sign.

At this point nothing is wiped. `@` still holds the old copies underneath
the mounts, so a forgotten path just keeps working from `@`.

# Stage 3: the wipe (commit 4)

The initrd unit, enabled by `datum.impermanence.wipe`. It is ordered after
the LUKS unlock and before `/sysroot` is mounted:

    boot.initrd.systemd.services.rollback-root = {
      description = "Move the old root aside and create an empty @";
      wantedBy = ["initrd.target"];
      requires = ["dev-mapper-crypted.device"];
      after = ["dev-mapper-crypted.device"];
      before = ["sysroot.mount"];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /btrfs_tmp
        mount -t btrfs -o subvolid=5 /dev/mapper/crypted /btrfs_tmp
        if [ -e /btrfs_tmp/@ ]; then
          mkdir -p /btrfs_tmp/old_roots
          mv /btrfs_tmp/@ "/btrfs_tmp/old_roots/@-$(date +%Y%m%d-%H%M%S)"
        fi
        btrfs subvolume create /btrfs_tmp/@
        umount /btrfs_tmp
      '';
    };

To check while building it: that `mount`, `date`, `mv` and `btrfs` are all
in the systemd initrd. btrfs-progs is there because root is btrfs. The rest
may need `boot.initrd.systemd.extraBin` or `storePaths`.

And in stage 2 a daily cleanup service: delete `old_roots/@-*` older than 14
days, parsing the date **from the name**. The directory's mtime is the old
root's `/` mtime, which hardly ever changes. It also needs
`btrfs subvolume delete --recursive` (or listing the nested subvolumes
first) because of the nested subvolumes above. Check that the btrfs-progs
in nixpkgs has `--recursive`.

Rollout:

1. `nh os boot .`, reboot. Repeat stage 2's checks.
2. Look at what the previous boot wrote into the volatile root:

        sudo find /mnt/btrfs-root/old_roots/@-<newest> -xdev -type f \
          -newermt '<boot time>'

   Anything there that should have survived goes on the list.
3. Repeat for a few days of normal use, including a nightly upgrade, a
   rustic run and a suspend cycle.

**Rescue.** Booting an older generation does not undo the wipe. The wipe
changes the disk before any generation loads, so every generation starts
from whatever `@` the last wiped boot left. What matters is whether that
generation has preservation:

- **Any generation from stage 2 on** (preservation enabled, wipe on or
  off) gets its state from `/persist` and works normally. This is the
  first fallback, and once stage 2 is in, every later generation qualifies.
- **A generation from before stage 2** boots, but without any state: no
  Wi-Fi, a new machine-id, no Tailscale identity, no face templates. And
  sops can't find its age key, so `rik-password-hash` can't be decrypted
  and **rik is locked**. Don't use one of these as a fallback.
  `nh clean` (`--keep-since 4d --keep 3`) plus the nightly upgrades removes
  them within days of stage 2 anyway.

If no preserving generation boots, put the old root back from the
installer USB (Secure Boot off for the installer, as always; unlock with
the passphrase):

    mount -o subvolid=5 /dev/mapper/crypted /mnt/x
    mv /mnt/x/@ /mnt/x/@-broken
    mv /mnt/x/old_roots/@-<newest> /mnt/x/@

then boot a generation without the wipe. The initrd emergency shell is
locked, so don't count on it.

Revert: set `datum.impermanence.wipe = false`. Preservation keeps working
without the wipe.

# Stage 4: backups and cleanup (commits 5+)

- `systemStatePaths` becomes the preserve list, or simply `/persist`. One
  list instead of two that can drift. Consider making `backups.nix` read it
  from `config.preservation` so it's defined once.
- Add `@persist` to btrbk. That gives system state atomic snapshots too,
  which it never had (`backups.nix:77`).
- Update the reinstall sequence in `flake.nix`: restore into
  `/mnt/persist/...`, not `/mnt/var/lib/...`.
- CLAUDE.md: a line on impermanence under Hardware Context, and KNOWN-ISSUES
  if anything is deferred.

# Decisions for Rik

1. ~~sops~~: decided 2026-11-09. Persist `/var/lib/sops` in the initrd
   and keep standard paths everywhere else; `sshKeyPaths` cleared in
   d310054. See the preserve list.
2. ~~Old-root retention~~: decided 2026-11-09, 14 days.
3. ~~`/var/log`~~: decided 2026-11-09, all of it, for debugging.
4. ~~Users~~: decided and done 2026-11-09, `mutableUsers = false`, with
   root's password a sops hash (`root-password-hash`) so that root stays a
   second way in. See the survey section.
5. ~~VM~~: decided 2026-11-09, no VM. Rely on stage 2's no-wipe rehearsal
   and the rescue path.

6. ~~`/root/.bash_history`~~: decided 2026-11-09, let it go with the
   rest of `/root`.

Stage 0 is done. Next is stage 1 (the `@persist` subvolume).
