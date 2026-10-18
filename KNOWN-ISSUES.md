---
author:
- Claude
- Rik Kabel
title: Known issues
date: 2026-10-18
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

Every documented issue, workaround and deferred item in this config, gathered
from the comments that describe them. The comments are still where the full
reasoning lives; this file points at them and says whether each one is still
live.

Last reviewed: 2026-10-17.

## 1. Hardware under observation

### Replacement battery: garbled gauge readings, two shutdowns on battery
- **Background:** HP "Primary" pack, 83.9 Wh (7264 mAh, 3S, design minimum
  11.55 V). Fitted 2026-10-16, along with the AX210 card. It reports
  `charge_full` exactly equal to its design capacity and a cycle count of
  0, and has no serial number.
- **2026-10-17:** during a deliberate discharge test, the machine lost
  power at about 17:23, around an hour after being unplugged. There was no
  shutdown sequence. The log just stops, and the next boot found the
  journal "uncleanly shut down".
- **What the data shows** (upower history):
  - steady discharge from 99% at 17:02 to 92% at 17:21, at 15–21 W
    (peak 32 W)
  - voltage a healthy 12.3–12.4 V up to the last sample (17:22:38), far
    from the 11.55 V cutoff
  - the charge reading jumped around in the 15 minutes before the cut:
    22% (17:08), 42% (17:17), 100% (17:18), one 0 W rate sample, then
    92 → 83% in 90 s
- **2026-10-18:** a second discharge test, logged with the first version
  of the logger below (`battery-2026-10-18-1254.log`). Unplugged at about 12:55, at 30–35 W.
  This time it was a clean shutdown: at 12:59:55 upowerd asked logind to
  power off, because a reading of 2% (12:59:35) had crossed its
  `PercentageAction=2`. The configured `CriticalPowerAction=HybridSleep`
  fell back to power-off.
  - The real state throughout: about 97%, 12.22–12.25 V.
  - Garbled reads came every few seconds from about two minutes in:
    charge 111% (8032 mAh, more than the pack's capacity), 44–50% and 2%;
    voltage 65.53 V (0xFFFF, all bits set), 50.7, 32.7 and 16.1 V; rate
    0.4 W and 190 W.
  - On AC beforehand the readings were stable ("Full", 100%, 12.95 V),
    but that was only three samples.
  - The logger stopped by itself at 12:57:51, two minutes before the
    shutdown; nobody was at the laptop. An empty read wouldn't have
    stopped it (zsh makes it 0), so most likely a read from the battery
    blocked and never returned. The kernel logged nothing about it, and
    upower kept getting answers. The logger has been reworked so the next
    run shows which read it was.
- **Reading:** the gauge data (fuel-gauge chip in the pack → SMBus through
  the battery connector → the embedded controller → ACPI) is corrupted
  intermittently, and worse under load: it began within two minutes at
  33 W, against 15 minutes at 15–21 W the day before. 0xFFFF is a
  typical failed bus read. Suspects, in order:
  1. the pack's own gauge or protection board. An aftermarket-looking
     pack: no serial, cycle count 0, full capacity equal to design.
  2. the battery connector or its seating.
  3. the laptop side: the embedded controller, the SMBus lines or the
     charging circuit.

  The 10-17 hard cut (no shutdown sequence) is a second symptom that bad
  reads alone don't explain. A real loss of power fits the pack's
  protection tripping, or the connector, better than a board fault.
- **Next:** separate the pack from the laptop.
  1. Run the logger on AC for half an hour. Garbled reads on AC, at low
     current, point more at the connector or the board.
  2. Reseat the connector and check its pins.
  3. If the old pack is still around: repeat the discharge test with it.
     Clean readings mean the new pack is bad; the same garbage means the
     laptop side.
  4. Return the new pack to the seller if it's at fault.
- **Meanwhile:** upower's critical action fires on the first bad read of
  2% or below, so expect early shutdowns on battery. They're clean, so
  that's the safe failure; leave it be.

#### Discharge test

Run the logger in a terminal, then unplug the charger. It writes one line
every 10 s: time, status, percentage, then voltage, current and charge in
the kernel's raw units (µV, µA, µAh; 12936000 is 12.94 V). Each value is
synced to disk as soon as it's read, so the log survives a power cut. The
journal doesn't; it lost the last ~3 minutes before the 10-17 cut.

It is built to keep going when the battery's readings go bad. On 10-18
the first version stopped by itself, two minutes before the shutdown,
probably on a read that never returned. Now:
- each read has a time limit, and a failed or hung read logs `ERR:<field>`
  instead of stopping the loop
- if a read hangs anyway, the unfinished last line shows which field it was
- values are logged as they come, with no arithmetic, so a garbled value
  can't break it

```sh
log=~/battery-$(date +%F-%H%M).log; b=/sys/class/power_supply/BAT0
while :; do
  printf '%s' "$(date +%T)" >> "$log"
  for f in status capacity voltage_now current_now charge_now; do
    printf ' %s' "$(timeout -k 1 3 cat "$b/$f" 2>/dev/null || echo "ERR:$f")" >> "$log"
    sync "$log"
  done
  printf '\n' >> "$log"; sync "$log"; sleep 10
done
```

`upower --monitor-detail` in a second terminal shows the same readings
live.

A healthy run looks like this: the percentage falls one point at a time,
the voltage sinks slowly toward 11.5–11.6 V, and the machine warns and
shuts down cleanly at low charge. Signs of trouble: percentage jumps, a
cut-out while the voltage is still well above 11.6 V, or a fast voltage
drop under load. To check behaviour under load, run something heavy
mid-test, such as a local `nix build` or `stress-ng`.

#### After an unexpected power-off

Collect this soon after rebooting. Plugging in starts overwriting the
recent history.

1. Confirm the old boot ended abruptly:
   `journalctl -b -1 -n 30 --no-pager` (no "Powering off" at the end) and
   `journalctl -b 0 | rg uncleanly`.
2. Read upower's history. The files in `/var/lib/upower` are root-only,
   but D-Bus serves the same data without root:

   ```sh
   for k in charge rate voltage; do
     echo "== $k"
     gdbus call --system --dest org.freedesktop.UPower \
       --object-path /org/freedesktop/UPower/devices/battery_BAT0 \
       --method org.freedesktop.UPower.Device.GetHistory "$k" 3600 200 |
     rg -o '[0-9]{10}, [0-9.]+, (uint32 )?[0-9]+' | sed 's/uint32 //' |
     while IFS=', ' read -r t v s; do
       printf '%s %8.2f state=%s\n' "$(date -d @$t '+%F %T')" "$v" "$s"
     done | sort
   done
   ```

   States: 1 = charging, 2 = discharging, 4 = full. A `0.00 state=0` row
   marks upower starting at boot, so the rows just before it are the last
   readings. 3600 is the look-back in seconds; raise it for longer runs.
3. Keep the logger's file, if one was running.
4. Add the incident above, with the time, the last voltage and percentage,
   and whether the readings jumped.

## 2. Waiting on upstream: temporary, with a removal condition

### Zotero disabled — blocker resolved, ready to re-enable
- **Where:** `home/modules/productivity/office.nix:17`
- **What:** Zotero 10 needs Firefox ESR 140, which nixpkgs dropped
  (NixOS/nixpkgs#568692).
- **Status (2026-10-17):** fixed upstream, though not by the PR the comment
  names. #569006 was closed unmerged. The maintainers merged
  NixOS/nixpkgs#572466 instead ("reviving prebuilt Firefox 140 ESR"),
  2026-10-15. `pkgs.zotero` (10.0.4) evaluates on the current lock and is
  not marked broken.
- **Caveat from the PR author:** it may need `firefox-esr-140-bin-unwrapped`
  allowed as both unfree and insecure (`nixpkgs.config.permittedInsecurePackages`).
  Evaluating it here gave no error, but nothing has been built yet.
- **Next:** uncomment, build, and rewrite the comment, or drop it.

### Gaze: RGB camera given as `/dev/video0` instead of `usb:`
- **Where:** `modules/nixos/facial-auth.nix:54`
- **What:** Gaze 0.3.9's `usb:` resolver filters to `video/x-raw`, and the
  camera's colour node offers only MJPEG, so the RGB source has to be the
  device node itself. If the numbering ever shifts, face auth fails over
  to the password; nothing breaks.
- **Remove when:** Gaze's resolver accepts MJPEG-only nodes. Then switch
  back to `builtinCamera`.
- **No upstream issue is referenced.** Worth filing one, or noting it if
  one exists.

### Umbriel ignores `default_fullscreen` for sdl-freerdp
- **Where:** `assets/rik/umbriel.toml:301`, `assets/guest/umbriel.toml:292`
- **What:** the window rule uses `default_maximize_to_edges` instead, and
  Ctrl+Alt+Return switches to real fullscreen.
- **Upstream:** noctalia-dev/umbriel#422, **still open** (last activity
  2026-10-12).

## 3. Accepted risks with a guard in place

### noctalia / umbriel on their own pinned nixpkgs
- **Where:** `flake.nix:42`, `home/modules/desktop-integration/noctalia.nix:40`,
  `modules/nixos/desktop/umbriel.nix:28`
- **Risk:** if their glibc is older than ours, the system's Mesa fails to
  load ("eglGetDisplay failed"). This broke the shell on 2026-09-29
  (noctalia-dev/noctalia#4668, closed).
- **Guard:** an eval-time assertion that their glibc is at least ours, so a
  stale pin fails the nightly build instead of the session. Upstream now
  bumps nixpkgs within about an hour of a glibc change (e639a87e).
- **Review:** only if the assertion starts firing often.

## 4. Deferred or not yet done

### Gaze tuning
- **Where:** `modules/nixos/facial-auth.nix`
- `parallel_capture = "auto"`, line 91. Try it "once the serial setup has
  proven itself."
- `security.level = "high"`, line 97. Named as the next step up; the CPU
  should handle it.
- Anti-spoof threshold 0.8 → 0.95, line 104. Optional.

### Thunderbird accounts are not declarative
- **Where:** `home/modules/productivity/thunderbird.nix:3`
- **What:** SMTP + NNTP + RSS could never all be declared at once, so the
  accounts are managed by hand. The commented-out block is kept as a
  reference, and **its password entries were never tested** (`NOTE`,
  line 14).

### Monitoring exporter has placeholder settings
- **Where:** `modules/nixos/monitoring.nix:3`
- **What:** node_exporter is on with its defaults. The header says
  "Port/IP here are placeholders," but the module sets neither; it uses the
  default port with `openFirewall`. The Prometheus/Grafana server on the
  Proxmox host is still to be set up.
- **Next:** once the server exists, decide whether to restrict the firewall
  to the scraper, and fix the header.

### Nightly upgrade: two paths never tested
- **Where:** `modules/nixos/nightly-upgrade.nix`, `modules/nixos/remote-builder.nix:25`
- **What:** the fallback to a local build when nostrum is unreachable, and
  the skip-on-battery path. Neither has run for real yet. (This comes from
  session notes; the repo itself doesn't record it.)

### Syncthing GUI has no credentials
- **Where:** `home/modules/productivity/syncthing.nix:7`
- **What:** deliberate, because it binds to loopback only. The comment says
  to wire `guiCredentials.passwordFile` to sops if that ever changes.

### Firmware updates are manual
- **Where:** `modules/nixos/firmware.nix:7`, `deploy.sh` step 4
- **What:** fwupd only runs the daemon. Updates go through `deploy.sh`'s
  prompt or `fwupdmgr` by hand.

## 5. Workarounds for upstream behaviour (no removal condition)

These are stable fixes for upstream quirks, not tracked bugs. Listed so they
can be rechecked after big upstream changes.

| Workaround | Where | Recheck when |
|---|---|---|
| `hardware.system76.power-daemon.enable = false`. COSMIC mkDefaults it on, and it crash-loops fighting TLP's `pd` shim | `modules/nixos/power-management.nix:15` | the COSMIC module changes how it picks a power daemon |
| Noctalia's user unit forced onto `umbriel-session.target` (`mkForce`), otherwise it starts on top of COSMIC too | `home/modules/desktop-integration/noctalia.nix:58` | the HM module gains a target option |
| `restartTriggers` on gazed, which the upstream module lacks. Depends on `mutableConfig = false` | `modules/nixos/facial-auth.nix:130` | upstream adds triggers, or `mutableConfig` is flipped |
| btrbk lockfile in `/var/lib/btrbk`, plus `onFailure` added to the generated unit by name | `modules/nixos/backups.nix:263`, `:278` | the btrbk module grows an onFailure hook |
| `.rdp` MIME type shipped as a package, because nothing runs update-mime-database on `~/.local/share/mime` | `home/modules/desktop-integration/sdl-freerdp.nix:6` | — |
| `gcr-ssh-agent` disabled so 1Password owns `SSH_AUTH_SOCK` | `modules/nixos/onepassword.nix:36` | — |
| ConTeXt LMTX wrappers avoid `exec -a` (luametatex finds its root by its own path) | `pkgs/context-lmtx/default.nix:37` | — |
| Cheatsheet applet's data files copied by hand (`just install` can't run in the sandbox) | `pkgs/cosmic-ext-applet-cheatsheet/default.nix:12` | — |

## 6. Known limitations and gotchas

Permanent, documented caveats; nothing to fix. Here so they're in one place.

- **No battery charge thresholds.** The HP's ACPI battery exposes no
  `charge_control_*` files, so it always charges to 100%.
  `modules/nixos/power-management.nix:54`
- **The face-login keyring has a blank password**, set by hand in Seahorse
  on 2026-10-14. If it ever gets a password again, face logins leave it
  locked and Maestral stalls. `modules/nixos/facial-auth.nix:163`
- **Face templates are sealed to this TPM** (`storage.encrypt_templates`,
  on since 2026-10-17). BIOS, kernel and Secure Boot updates don't affect
  them, because the seal has no PCR policy. But clearing the TPM or moving
  `/var/lib/gaze` to other hardware makes them unreadable, and gazed
  refuses to start: re-enroll with `gaze add-face`. The same refusal
  happens if plaintext templates ever reappear (from an old backup, say),
  and the fix is the migration in `modules/nixos/facial-auth.nix`.
- **Face unlock on Noctalia's lock screen goes through PAM `login`**
  (hardcoded in noctalia). Since 2026-10-17 Gaze sits in `login` and not
  in `greetd`, which reaches it through `substack login`. On the lock
  screen: press Enter on the empty field, then look
  (`lockscreen.allow_empty_password` in `assets/rik/noctalia.toml`). A typed
  password also goes through Gaze first, so unlocking away from the camera
  waits for it to give up. Console (tty) logins accept a face too.
  `modules/nixos/facial-auth.nix`, the PAM comment block.
- **The TPM2 PIN breaks after a BIOS or dbx update** (PCR 7 changes). Use the
  passphrase, then re-enroll with `--wipe-slot=tpm2`.
  `hosts/datum/disko-config.nix:18`
- **`/var/lib/sbctl` is not backed up.** Recovery: turn Secure Boot off,
  create new keys, re-enroll. `modules/nixos/secure-boot.nix:23`
- **`mutableUsers`: declared passwords only apply when an account is
  created.** If rik ends up locked, the repair is in
  `modules/nixos/users/rik.nix:22`. Root has no declared password, so on a
  reinstall run `nixos-install` without `--no-root-passwd`
  (`modules/nixos/users/root.nix:3`).
- **UIDs/GIDs are pinned** (rik 1000, guest 1001/993). Changing them doesn't
  renumber existing accounts. `modules/nixos/users/rik.nix:13`
- **COSMIC snapshot:** settings changed after `cosmic-export` but before the
  next build get reverted. The wallpaper (in `$XDG_STATE_HOME`) is not
  carried. `home/modules/desktop-integration/cosmic-snapshot.nix:23`, `:33`
- **`gaze doctor` reports `pam_gaze.so` missing**, a false positive on
  NixOS. `CLAUDE.md`
- **statix W20 in `backups.nix`** is accepted on purpose.
  `modules/nixos/backups.nix:283`
- **Hidden dependency:** the backup share's `5cd-rack.local` lookup needs
  avahi, which is enabled in `printing.nix`, not in `backups.nix`.
  `modules/nixos/backups.nix:29`
- **`olde-toplevel.sh` matches names heuristically**, so it can miss
  packages, and it subtracts hand-listed packages that are also platform
  defaults (curl, openssh). `olde-toplevel.sh:73`, `:121`
- **Applet shortcut is set by hand:** the cheatsheet's Super+C binding
  lives in COSMIC Settings, not the repo.
  `home/modules/desktop-integration/cosmic-applet-cheatsheet.nix:15`

### Manual pin bumps
- lanzaboote: release tag, bumped by hand. `flake.nix:13`
- context-lmtx: bump `version`, rebuild, paste the new hash.
  `pkgs/context-lmtx/default.nix:11`
- cosmic-ext-applet-cheatsheet: set `rev`/`version`, blank both hashes, build
  twice. `pkgs/cosmic-ext-applet-cheatsheet/default.nix:7`

## 7. Defects and stale comments found while compiling this

None of these were documented as issues; they turned up while reading.

- **`WLR_NO_HARDWARE_CURSORS = "1"`** in
  `modules/nixos/system-environment.nix:10`. The comment says
  it's for virtual machines; datum is bare metal. Check whether it's still
  wanted.
- **Stale comment** at `modules/nixos/remote-builder.nix:5`. It says noctalia
  "builds from source now that its input follows our nixpkgs". That stopped
  being true on 2026-10-15, when noctalia came off `follows`.
- **Stale comment** at `modules/nixos/networking.nix:32`. The commented-out
  example uses `"wlan0"`; the interface is `wlp59s0`.
- **Unfinished comment** at `home/modules/shell/zsh.nix:22`: "dummy address
  to satisfy" what?
- **Old header paths** (`~/Projects/datum-config/…`, from before the
  `modules/` layout) in `modules/nixos/bluetooth.nix:1`,
  `modules/nixos/desktop/cosmic.nix:1`, `modules/nixos/backups.nix:1`,
  `hosts/datum/laptop-configuration.nix:1`, `home.nix:1`, `mksecrets.sh:2`.
  Also `home/modules/unix-tools/claude-code-rik.nix:1` calls itself
  `claude-rik.nix`.
- **Noctalia options it no longer recognises** in
  `assets/guest/noctalia.toml:66`, `:73`, `:106-108` (`# unknown setting
  …`: password hint, ui_scale, weather location). These came from an older
  export; rik's copy doesn't have them. Re-export, or delete them.
- **`hosts/datum/hardware-configuration.nix:3`** points at
  `/etc/nixos/configuration.nix`. That's the generator's boilerplate and
  harmless, but the path doesn't exist here.
