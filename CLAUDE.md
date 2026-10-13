# System & Hardware Context

- OS: NixOS, unstable channel. Fully flake-based.
- Config: this repo (`~/Projects/datum/datum-config`). There is no
  `/etc/nixos/` — the directory does not exist, so anything that falls back to
  channels or `<nixos-config>` will fail.
- Host attribute: `datum` (`nixosConfigurations.datum`, defined in `flake.nix`).
- Hardware: HP Spectre x360 15-ch00x (since 2026-10-12), i7-8550U, NVIDIA
  MX150, 16 GB, 1 TB NVMe, TPM 2.0. Disk layout is managed by disko: LUKS
  around btrfs, unlocked at boot by TPM2 + PIN (PCR 7, so it depends on
  Secure Boot), with the passphrase and a recovery key as fallbacks; all
  three are in 1Password. The initrd is systemd-based (nixpkgs' default;
  the repo doesn't set `boot.initrd.systemd.enable`), so systemd-cryptsetup
  does the unlock. Its crypttab options (`tpm2-device=auto`, `tries=0`)
  live in `hosts/datum/disko-config.nix`; `tries=0` matters, see the
  comment there. After a BIOS or dbx update the PIN may stop working: use
  the passphrase once, then re-enroll (command in the disko header).
- Boot: Secure Boot ON, via lanzaboote (`modules/nixos/secure-boot.nix`)
  with our own sbctl keys in `/var/lib/sbctl` plus Microsoft's. Lanzaboote
  replaces systemd-boot (`boot.loader.systemd-boot.enable` is mkForced
  off). The ESP holds signed stubs; the kernel itself shows as unsigned in
  `sbctl verify`, which is expected (the stubs check it by hash). The
  firmware is AMI Aptio with HP consumer menus: Secure Boot lives under
  System Configuration → Boot Options. Never "Clear All Secure Boot Keys"
  casually; it wipes dbx too. If it won't boot, turning Secure Boot off in
  the BIOS is the safe fallback.
- Desktop: COSMIC (`cosmic-greeter` via greetd). Note that `cosmic-greeter` is
  a single PAM service covering both the login screen and the session lock
  screen.
- Authentication: GunduLabs Gaze (`gazed` daemon + `pam_gaze.so`), see
  `modules/nixos/facial-auth.nix`.

## Rebuilding

Use `nh` (what `deploy.sh` drives), from the repo root:

    nh os switch .

or plain nixos-rebuild with an explicit flake ref:

    sudo nixos-rebuild switch --flake .#datum

A bare `nixos-rebuild switch` does NOT work here — it drops to legacy channel
mode and dies looking for `<nixos-config>`.

## Cameras

- Built-in HP Wide Vision FHD (SunplusIT, `0408:5251`), RGB + IR, and it
  works. One USB device, two UVC functions: colour MJPEG up to 1080p
  (`/dev/video0`) and IR 352x352 GREY (`/dev/video2`). Gaze uses it for both
  spectra: IR pinned as `usb:0408:5251`, RGB as `/dev/video0`, because
  Gaze 0.3.9's `usb:` resolver skips MJPEG-only nodes (see facial-auth.nix).
- The IR emitter strobes on alternate frames by itself whenever the IR stream
  starts (Microsoft camera XU, unit 7, selector 6, already in mode 2), so Gaze
  needs no emitter profile and `emitter_enabled` stays off. Details and
  measurements are in `modules/nixos/facial-auth.nix`.
- History, for this file's older commits: the previous datum hardware (the
  13-ac, until 2026-10-12) had a built-in camera with broken firmware and ran
  face auth off an external AVerMedia CAM 313 (`usb:07ca:313a`) with no IR.
  None of that applies now; see commit c2c5199 if it ever matters.

# Technical Constraints & Guidelines

- Gaze packaging: do NOT write a custom derivation or overlay for it. Upstream
  ships a flake with `packages.*` and a full `nixosModules.default` (systemd
  unit, D-Bus and polkit policy, PAM wiring). It is a flake input; configure it
  through `services.gaze.*`. Never `curl | sh`.
- Gaze on NixOS: `gaze doctor` reports `pam_gaze.so is not installed where PAM
can load it` as an error. This is a FALSE POSITIVE — it probes FHS paths like
  `/lib/security`, which do not exist here, while NixOS references PAM modules
  by absolute store path. Do not "reinstall the base package" in response.
- PAM: keep the password a working fallback in every stack. The gaze rule goes
  in as `sufficient` ahead of `pam_unix`. Do not assign literal `order` numbers
  — offset from a neighbouring rule, since nixpkgs renumbers between releases.
- Model files: Gaze downloads its ML models (SCRFD, ArcFace, MiniFASNet-V2) on
  first use. The daemon runs with `ProtectSystem=strict`, so cache must stay
  under `/var/cache/gaze`.
- 1Password: installed via `programs._1password{,-gui}`, not `home.packages` —
  the GUI needs a setuid browser-support helper and a polkit policy. It also
  owns the SSH agent; `services.gnome.gcr-ssh-agent` is deliberately disabled.
  The agent only listens while the app is running, hence the autostart entry.

# Architecture

- Target: modular dendritic structure, one app/tool per file. System modules in
  `modules/nixos/`, Home Manager modules in `home/modules/`, per-host
  composition in `hosts/<host>/`.
- Multi-user: keep system-level privileges separate from user-level Home
  Manager ones. Users must be able to change their own config without full
  system rebuild access — see the standalone `homeConfigurations` in
  `flake.nix`, which apply without sudo.
- Decoupling: Home Manager modules should remain extractable and usable
  independently of `nixosConfigurations`.

# Architectural Rules

- Avoid multi-file global rewrites in a single command.
- Validate incrementally with `nix eval` or `nix flake check` before rebuilding.
- Follow idiomatic module structure using `options`, `config`, and `imports`.
- Statix and deadnix are installed and should be used.
  - Known, accepted statix warning: W20 (repeated `systemd` key) in
    `modules/nixos/backups.nix`. Ignore it. The separate `systemd.*`
    assignments are intentional (each unit sits with its section), and the
    reason is commented at the first one. Don't merge them to silence statix.
- Use the `mcp-nixos` tool to query accurate package names, options, and Home Manager attributes before suggesting changes.
