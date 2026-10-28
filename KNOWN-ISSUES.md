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

Last reviewed: 2026-10-23.

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
- **2026-10-18, afternoon:** a third test, with the reworked logger. On
  battery from 14:55 to 15:06 at 15–34 W (average 19.5 W), then 34
  minutes on AC. No shutdown, and no read hung or failed.
  - The real state on battery: 100% down to 96%, voltage falling
    smoothly from 12.98 to 12.38 V.
  - Garbled reads from about five minutes in, mostly between the
    logger's samples. Upower recorded 100% (15:00:09 and 15:01:35, at a
    real 98%), 90% (15:00:31, also in the log, while the charge field
    said 98%) and 22% (15:04:38). The log also has one current of
    0.09 A (15:04:45) among steady 1.3–2.7 A.
  - On AC (15:06–15:40, about 205 samples): clean. The percentage rose
    96 → 100% one point at a time, voltage 12.79–13.01 V, charge
    6976 → 7232 mAh, then a 0.25 A trickle near full.
- **2026-10-18, connector inspection:** with the bottom cover off
  (photos taken, not in the repo):
  - The laptop's header has 12 pins, straight, evenly spaced and level,
    with clean solder joints. It's keyed by a small asymmetry at one
    end; it looks almost reversible, so don't force it.
  - The pack's plug has 12 contacts, evenly recessed, with no
    darkening or melting. Probably 4 red (+), 4 black (−) and 4 signal
    wires (green, white, grey, yellow: SMBus clock and data, and likely
    temperature and presence). The wires enter the housing through a
    hand-applied blob of glue, typical of aftermarket packs.
  - One pin was slightly bent; it had still been inserting properly.
    Rik straightened it and reseated the plug.
- **2026-10-18, after the reseat:** unplugged at about 16:42; no
  change. Upower recorded false readings from three minutes in: 100%
  (16:45:30, 16:48:46, 16:54:20, 16:57:26) and 4% (16:45:34), while
  the real charge fell smoothly 99 → 94% at about 12.5 V. The log
  (`battery-2026-10-18-1641.log`) had no `ERR` entries.
- **2026-10-23: two more hard cuts.** After five days on the HP brick,
  Rik moved rooms and plugged into an Anker USB-C charger (the 65 W one,
  though at first it was taken for the 140 W; see the correction below),
  with nothing else plugged into it. The laptop's charging LED lit, but upower says the pack
  discharged the whole time, at 16–30 W
  (the full system load), so the laptop wasn't running on USB-C power at
  all. Not logger-run; reconstructed from upower history and the journal.
  - 12:13:41 unplugged from the brick. Within 12 s a false 3% (real 98%);
    that's the "battery at 3%" warning Rik saw.
  - 12:14–13:08: the real charge fell smoothly 98 → 79%, with the usual
    false readings in between (100%, 3%, 8%, 19–21%, 36–37%, 71–75%;
    rates of 0, 0.4 and 97–188 W).
  - About 13:08:40: **hard cut** at a real ~79%. The journal stops, with
    no shutdown sequence.
  - 13:09:46: booted on battery (`ADP1` off-line) and cut again after
    **44 s**, also with no shutdown sequence.
  - 14:31: booted on the brick, charging normally (93 → 96%, rate
    tapering 10.9 → 6.9 W, no false readings).
  - Still consistent: every false reading and every cut has come while
    the pack supplies the power. The new part is that the hard cuts
    repeat, at about 80% real charge, once within a minute of booting.
    That's the pack's protection cutting the output, not upower reacting
    to a false reading.
  - The real discharge matches upower's rate (19% of 84 Wh in 55 min is
    about 17 W), so the charger supplied little or nothing, even though
    the LED meant the EC had seen it. `ADP1` read off-line at the
    13:09:46 boot, and the kernel logged no UCSI/Type-C events at
    plug-in. Not output sharing: the laptop was the only device on the
    charger. The cause is open. In rough order of likelihood:
    1. The PD negotiation landed on a low contract, 5 V, or failed. Some
       HP firmware won't take power from a non-HP source, or caps it,
       usually with a boot-time "low power adapter" warning.
    2. The cable: a non-e-marked cable limits the contract to 3 A, and
       some cables are charge-only at low power.
    3. The port: only one of the two Type-C ports may accept power.
    4. The bad pack: if the EC reads false battery data, it may refuse
       or throttle charging from a source it trusts less than the HP
       brick.
  - **Correction, same day:** the charger was actually Rik's 65 W Anker
    (the 140 W had been swapped with it by mistake). Retested on it at
    15:03, alone on the charger: `ADP1` online, battery charging, and the
    state held at charging (1) through an `nh os switch` (about
    15:05–15:09; a short build, so a light test). UCSI read
    `VOLTAGE_MAX=5000000`, `CURRENT_MAX=3000000`, `CURRENT_NOW=3250000`.
    3.25 A is the 20 V current of a 65 W source and a 5 V contract can't
    exceed 3 A, so the contract is most likely 20 V / 65 W and UCSI's
    voltage fields are unreliable on this machine.
  - **Then a spontaneous dropout:** at 15:10:27, 90 s after the build,
    with nothing touched, the supply dropped on the SS + bolt port.
    Discharging at 15–20 W until Rik replugged at about 15:12:53. The
    journal logged nothing at all.
  - **Port and wiggle test** (logger below, 5 s samples:
    `charger-2026-10-23-1525.log` and `-1718.log` in ~/Projects/datum).
    UCSI maps the ports: `USBC000:002` is the SS + bolt port, `001` the
    bolt-only one.
    - SS + bolt: about an hour hands-off (15:19–16:14), then the cable
      wiggled at both ends. Clean.
    - Bolt-only: about an hour hands-off (16:15–17:18), then wiggled.
      Clean. A second hour (17:18–18:17) was clean apart from one
      sample at 18:13:31, when Rik knocked the plug out by accident;
      the wiggles after he reconnected were clean.
    - Upower's history, which records state changes as they happen,
      agrees. No failed reads.
  - **Conclusion:** both ports charge, and the cable isn't loose at
    either end. The dropouts are intermittent and silent (no kernel
    event), and the test couldn't reproduce them. Cable, charger and the
    laptop's input side are all still possible. With this pack an
    unnoticed dropout ends in a hard cut, so: use the HP brick when
    unattended; on USB-C, run the logger (it raises a desktop
    notification when AC goes off-line); swap the cable or try the
    140 W charger one at a time to narrow it down.
  - The logger used here:
    `/tmp/claude-1000/…/scratchpad/charger-logger.sh LOG [SECONDS]`. It
    lives in the session scratchpad, so it won't survive; make it a user
    service in the repo if it's needed again.
- **2026-10-27: two more hard cuts, then the pack stopped charging on the
  brick.** Rik started the day on USB-C, saw 45% there, and moved to the HP
  brick. Reconstructed afterwards from upower history and the journal; no
  logger ran.
  - 10:20–10:28: discharging (state 2) from 99 to 97% at about 15 W, with
    the usual false readings (89%, 22%). **Hard cut at 10:28:32**, at a
    real ~97%: the journal just stops, and the 10:29 boot found it
    "uncleanly shut down". `ADP1` read on-line at that boot.
  - 10:29–11:50: the state flipped between charging (1), discharging (2),
    fully charged (4) and pending-charge (5), mostly 5 after 10:43, yet the
    real charge fell steadily, 96 → 57%. That's about 33 Wh in 80 minutes,
    or ~25 W, the whole system load: the pack powered the laptop while the
    EC reported AC. False readings throughout (1–39%, 100%), and rate spikes
    of 94–218 W.
  - This is the **first garbling seen with AC reported present**; every
    earlier false reading came while the pack was plainly discharging. It
    fits the 10-23 picture, where the pack carried the load while the
    charger was plugged in.
  - **Hard cut at 11:49:56**, at a reported 57%: the log ends in audio DMA
    errors with no shutdown sequence, and the 12:16 boot found the journal
    "uncleanly shut down".
  - Since 12:16, on the brick (`ADP1` on-line): **not charging**. upower
    reads a flat 45%, `pending-charge`, 0 W, sysfs `status=Not charging`,
    across four boots and seven hours (still so at 19:22). The voltage sits
    at 11.38 V, 3.79 V a cell. That fits a resting pack at roughly half
    charge, and is well under the 12.2–13.0 V seen on 10-18 at 94–100%.
    The 57 → 45% step happened across the 11:50–12:16 power-off.
  - A flat value for seven hours, on AC, looks like a stuck gauge or
    charging deliberately blocked by the EC or the pack's protection
    board. Until today the brick charged it normally (10-23: 93 → 100%;
    10-25: full).
  - The charging LED is steady white. On HP laptops that usually means AC
    connected and battery full, or at least not charging; amber means
    charging. (Not checked against this model's manual.) So the EC itself
    sees nothing to charge, and isn't signalling a fault with a blinking
    LED. That points at what the pack tells the EC, such as a "fully
    charged" or "charge inhibit" status from its gauge or protection
    board, rather than at the charger or the charging circuit, even though
    the percentage the EC passes on to ACPI says 45%.
  - upower's history also holds an entry dated 11-13 (74%, 12.3 V,
    charging), two weeks in the future. It's a corrupt record, not a clock
    problem: the system clock was right.
  - **Evening battery run, a fifth hard cut.** Instead of retrying USB-C,
    Rik unplugged both the charger and the external monitor at 19:32.
    - The pack carried 17–30 W, discharging steadily. The voltage sagged
      from 11.38 V at rest to 10.97–11.19 V under load. There were false
      readings of 10% (19:35:23) and 4% (19:38:13) against a real ~44%.
    - **Hard cut at about 19:43:43**, mid-use (a launcher toggle, then
      Alt+Tab, then nothing). There was no shutdown sequence, and the next
      boot found the journal "uncleanly shut down". upower's on-disk
      history stops at 19:38:13 because it saves in batches, so the last
      few minutes were lost with the cut.
    - It wasn't empty: energy went 37.7 → 33.6 Wh (45 → 40%), matching
      about 11 minutes at ~20 W, and the cells sat around 3.7 V under
      load, far above a ~3.0 V cutoff. So the protection board cut the
      output, as on 10-23. The cuts have now come at 97%, ~80% and 40%,
      so charge level isn't the trigger.
    - While the machine was off, the white LED kept blinking slowly. A
      ~10 s hold of the power button stopped it. The meaning of a blinking
      white LED on this model isn't checked; it may be the EC flagging
      low battery or a battery error.
    - Back on the brick (boot at 19:48): still **not charging**. upower
      reads 40%, pending-charge, 0 W, and sysfs `Not charging`, with the
      LED steady white. The voltage creeps 11.31 → 11.33 V over 20
      minutes, which is a resting pack recovering, not charge going in.
      The power-button hold didn't restore charging.
  - **Status:** the pack can't run the laptop (five hard cuts at any
    charge level) and won't take a charge. A 15 s power-button hold with
    the brick unplugged (HP's hard reset) changed nothing, so the pack has
    been **disconnected inside** since the evening of 10-27.
  - **Running without a battery** (checked 21:03): it boots and runs on
    the brick alone. `BAT0` is gone, upower shows "0% (should be
    ignored)", `ADP1` is on-line, and `systemd-ac-power` says yes, so the
    nightly upgrade's battery skip doesn't trigger. No CPU cap is visible:
    max 4.0 GHz, turbo on, `max_perf_pct=100`, RAPL PL1 15 W / PL2 25 W
    (the i7-8550U's stock limits), and a 5 s all-core load averaged
    2148 MHz. There is no with-battery baseline to compare against, so
    "not throttled" is inferred from the limits being stock. Any power
    blip is now an instant hard power-off.
  - **The LED:** yellow while charging, white when full (Rik's
    correction). So from 12:16 the EC took the pack as *full* at 45%.
    That's the pack's gauge or protection board reporting a false "full"
    or "charge inhibit", not the charger. With no pack, the LED is simply
    white for "AC connected", so it gives no further diagnostic.
  - The removed pack sits at ~40%, a reasonable storage level. Keep it
    somewhere cool and non-flammable, check it for swelling, and recycle
    it rather than keep it.
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
  1. ~~Run the logger on AC for half an hour.~~ Done 10-18: clean. So
     far every garbled read has come while the pack supplies the power,
     which points away from a constant fault on the data lines and toward
     something under discharge: the pack's gauge or protection board, or
     a contact that fails under current. One run is not proof.
  2. ~~Reseat the connector, check its pins, repeat the discharge
     test.~~ Done 10-18: nothing visibly wrong on either side, and the
     garbled reads continued. That leaves the pack's gauge or
     protection board as the main suspect.
  3. If it still garbles, return this pack to the seller.
  4. ~~Buy a replacement against HP's battery code and spare-part number
     from the manual, not just "fits Spectre x360 15": 3-cell, 11.55 V,
     about 84 Wh. Distrust much higher claimed capacity. Prefer a stated
     warranty and a return window of 30 days or more, and reviews that
     mention the charge reading and sudden shutdowns, not just runtime.~~
     Chosen 2026-10-27: **BTI `YB06XLBTI`** from **ProVantage**. Returns
     within 30 days, "100% satisfaction or defective", by mail. Notes
     from choosing it:
     - The 15-ch takes **YB06XL**. KB06XL is the older 15-bl pack.
       Listings give HP's YB06XL spares as `926372-855`, `928427-271`,
       `HSTNN-DB8H` and `TPN-Q200` (among others); check them against the
       removed pack's label.
     - BTI (now distributed by Origin Storage) sells to business IT
       buyers, and is an honestly labelled compatible pack from an
       accountable US channel. Its claim of grade-A Japanese/Korean cells
       is the vendor's own.
     - Rejected: reliablelaptopparts.com, $64.99 "Brand New Genuine
       Original HP". Its contact page lists a Shenzhen factory, a Chinese
       phone number and a Gmail address, there's no HP spare number or
       date, and it's far too cheap for genuine discontinued stock: an
       aftermarket pack with an HP label, the same profile as the pack
       that failed. Also passed over: Micro Center (same BTI pack, but
       returns in store only, at Cambridge) and LaptopBatteryExpress
       "Xtend" ($145.90, claimed Samsung cells, 2-year warranty, Digital
       Day Inc., Ohio). Xtend is legitimate, but the cell claim can't be
       verified.
     - Genuine HP new old stock would be made around 2019–21. Shelf-aged
       packs may be at 80–90% capacity, or locked out if they sat drained.
  5. Acceptance-test it within the return window. Keep the box, note the
     delivery date, and test in the first week:
     - Before use, record what the pack reports: `manufacturer`,
       `model_name`, `serial_number`, `cycle_count`, `charge_full` vs
       `charge_full_design` in `/sys/class/power_supply/BAT0/`, and
       `upower -i`. A serial number, a real manufacture date and a full
       capacity a little *below* design are good signs. The failed pack
       had no serial, a cycle count of 0, and full exactly equal to
       design.
     - Charge to full on the brick. The LED should go yellow, then white,
       with upower showing `charging`, a positive rate and a rising
       voltage.
     - A 1–2 hour discharge, with the logger under "Discharge test", and
       upower's history checked afterwards for jumps (the logger misses
       readings between samples). Any false reading or cut is grounds to
       return it as defective.
     - If a reputable pack garbles too, suspect the laptop side.
- **Pack history:** this laptop's battery has been replaced several
  times.
  - The old pack (itself the second or third) is worn out. It holds
    only a surface charge and goes from 98% to 0% in seconds under load,
    so it's no use for a comparison test. At most it could show, on AC,
    whether a different pack also reads garbage. Don't refit it if it's
    swollen.
  - The first replacement worked for less than a day. Left on and
    unplugged overnight, it was at 6% in the morning and after that
    wouldn't take a charge. That fits a protection board locking out
    after a deep discharge, common in cheap packs.
  - This pack is the second replacement. It charges normally, so the
    laptop's charging circuit isn't simply dead. Both replacements went
    through the same connector and EC, though, so the inspection in
    step 2 matters.
  - HP discontinued this battery over a year ago and new old stock
    can't be found. The more reputable third-party packs cost about
    three times what this one did.
- **Meanwhile:** treat the pack as unusable on battery (revised
  2026-10-23, after two hard cuts in a row at ~80%). Keep datum 15 on the
  HP brick. A clean shutdown, from upower's critical action firing on a
  false reading of 2% or below, is the good outcome now; the hard cuts
  risk the btrfs filesystem and whatever is open. Watch the pack for
  swelling or heat, and replace it rather than settling for
  semi-portable use. Since 2026-10-27 the pack doesn't charge on the
  brick either, so it can't bridge even a brief power loss; any blip at
  the wall or the plug is likely to end in a hard cut. Since that evening
  it has been disconnected, and datum 15 runs on the brick alone until
  the BTI pack arrives: shut down before unplugging.

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

### NAPS2 disabled: patchelf 0.19.2 crashes on its .NET deps
- **Where:** `home/modules/productivity/office.nix:8`
- **What:** the 2026-10-20 nightly upgrade failed building naps2 8.3.2.
  nixpkgs moved patchelf from 0.15.2 to 0.19.2 between the 2026-10-15 and
  2026-10-17 locks, and patchelf 0.19.2 aborts with
  `Assertion splitIndex == -1 failed` adding an rpath to `crossgen` in
  `runtime.linux-arm64.Microsoft.NETCore.App-2.1.30`, a prebuilt NuGet
  package in naps2's dependencies. cache.nixos.org had no build of the
  new naps2 either, so Hydra most likely fails the same way.
- **Upstream:** no nixpkgs issue found on 2026-10-20.
- **Remove when:** `nix build nixpkgs#naps2` succeeds against a fresh
  lock, or the output is in the cache. Then uncomment it and drop the
  comment.

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
