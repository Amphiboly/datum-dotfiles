# System & Hardware Context

- OS: NixOS, unstable channel. Fully flake-based.
- Config: this repo (`~/Projects/datum/datum-config`). There is no
  `/etc/nixos/` — the directory does not exist, so anything that falls back to
  channels or `<nixos-config>` will fail.
- Host attribute: `datum` (`nixosConfigurations.datum`, defined in `flake.nix`).
- Hardware: HP Spectre x360 13-ac076nr, i7-7500U, TPM 2.0, booting via
  lanzaboote. Disk layout is managed by disko.
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

- Built-in camera is BROKEN and unusable. It should be an HP TrueVision FHD
  RGB-IR (`064e:3401`) but since 2026-08-14 it enumerates as a bare SunplusIT
  SPCA2085 (`1bcf:0b09`) offering one 160x120 YUY2 mode and no IR, with corrupt
  UVC control metadata. The driver is `uvcvideo` (not `gspca`). Diagnosed to
  exhaustion — do not re-litigate it; the full history is in
  `modules/nixos/facial-auth.nix` and commit c2c5199.
- Face auth therefore runs off an external USB webcam, an AVerMedia Live
  Streamer CAM 313, pinned by VID:PID as `usb:07ca:313a`. It is only
  occasionally connected; its absence must stay fast, which is why the camera
  is pinned rather than left at Gaze's `"primary"` default.
- No IR anywhere, so software liveness is the only anti-spoofing. Known and
  accepted; datum is a backup laptop.

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
- Use the `mcp-nixos` tool to query accurate package names, options, and Home Manager attributes before suggesting changes.
