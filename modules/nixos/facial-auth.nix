# modules/nixos/facial-auth.nix
#
# Face unlock via Gaze (https://gaze.gundulabs.com). Upstream ships a proper
# NixOS module — daemon, D-Bus/polkit policy, PAM wiring — so this file only
# carries datum-specific policy: which PAM stacks get a face factor, and how
# strict the matcher is.
#
# Pairs with inputs.gaze.nixosModules.default, imported in hosts/datum.
#
# CAMERA: this uses an EXTERNAL USB webcam, because datum's built-in camera is
# broken. The internal module is an HP TrueVision FHD RGB-IR (064e:3401) and it
# worked here for 60 clean enumerations between the 2026-07-13 install and
# 2026-08-14 14:57:34. By 15:59:22 the same hardwired port (1-5) was
# enumerating a generic SunplusIT SPCA2085 (1bcf:0b09) offering one 160x120
# YUY2 mode and no IR stream, and it has stayed that way since.
#
# Ruled out with direct evidence: driver and kernel (the stub is in the raw USB
# descriptor, below uvcvideo), uvcvideo quirks (a modprobe option cannot change
# a VID:PID), a kernel regression (it worked and broke on 7.1.8), an
# intermittent firmware load (a port power-cycle re-enumerated it unchanged),
# EC and residual power state (a 4.5-minute drain with AC removed), every
# relevant BIOS setting, and a full teardown on 2026-08-23 that found no loose
# or damaged connector.
#
# The module is live but its firmware image is corrupt: the IR emitters still
# fire on stream start, while the UVC control metadata it reports is garbage
# (contrast min=26996 > max=17659, sharpness flagged both read-only and
# write-only, defaults outside their own ranges). A clean ROM fallback reports
# coherent ranges. No public reflash image or tool exists for 064e:3401, and
# nothing in LVFS covers it, so the internal camera is written off.
#
# NO IR ANYWHERE, THEREFORE WEAKER ANTI-SPOOFING. The external camera is an
# RGB streaming webcam, so `liveness` (MiniFASNet-V2) is the only thing between
# a match and a photograph. That model is decent against a phone screen or a
# flat print but it is not the boundary an IR sensor gives you. Accepted
# deliberately here: this is a backup laptop.
{
  config,
  lib,
  ...
}: let
  # The single switch for whether face auth participates in authentication.
  # False still builds and runs the daemon but keeps pam_gaze out of every PAM
  # stack, which is how this sat between 2026-08-22 and 2026-08-23 while the
  # camera situation was unresolved.
  activeInAuthStack = true;

  # AVerMedia Live Streamer CAM 313, 1080p30 MJPEG. Pinned by USB VID:PID
  # rather than left at the "primary" default, for three reasons:
  #
  #  1. Correctness. "primary" resolves the primary color camera at runtime,
  #     and with the broken internal camera still enumerating as a valid color
  #     source it could pick that one instead.
  #  2. Speed when absent — the point that matters most here, since this camera
  #     is only occasionally plugged in. An unmatched `usb:` spec fails on a
  #     sysfs/GStreamer device scan bounded by a 100ms settle timeout, so PAM
  #     falls straight through to the password. Left at "primary" the bad
  #     internal camera would instead open, stream, and burn up to
  #     liveness.max_frames (40) hunting for a face in a 160x120 frame.
  #  3. Greeter support. `usb:` and node specs build a v4l2src pipeline, which
  #     works in a greeter that has no PipeWire session; "primary" needs one.
  #
  # VID:PID also survives being moved to a different USB port, which a pinned
  # PipeWire node name would not.
  externalCamera = "usb:07ca:313a";
in {
  services.gaze = {
    enable = true;

    # GTK4 enrollment/settings app. `gaze add-face` does the same job from a
    # terminal if you'd rather not carry GTK4 on this machine.
    gui.enable = true;

    # Keep /etc/gaze/config.toml owned by this repo rather than seeded once
    # and then left mutable (upstream's default, matching deb/rpm noreplace).
    # The cost is that the GUI's *settings* page can no longer write — set
    # this back to true if you'd rather tune thresholds from the GUI. Face
    # enrollment is unaffected either way; templates live in /var/lib/gaze.
    mutableConfig = false;

    # Upstream defaults this to ["sudo" "polkit-1"]. Emptying it withholds the
    # face factor from every service at once.
    pam.defaultServices =
      lib.optionals activeInAuthStack ["sudo" "polkit-1"];

    settings = {
      cameras.rgb = externalCamera;

      # With no IR this is the sole anti-spoofing measure, so it stays on. 0.8
      # is upstream's default; raise it toward 0.95 to trade convenience for
      # strictness.
      liveness = {
        enabled = true;
        threshold = 0.8;
      };

      auth = {
        # Never try to authenticate a face for an SSH session, and never while
        # the lid is shut — both would just burn the retry budget.
        abort_if_ssh = true;
        abort_if_lid_closed = true;
      };

      # If an IR-capable camera ever arrives, add it here — IR sees warm skin
      # rather than a screen or a print, works in the dark, and would let the
      # liveness caveat at the top of this file be dropped. Find the node with
      # `gaze doctor`; on an RGB-IR module the IR stream is usually a second
      # capture node reporting GREY/Y8 rather than YUY2. A `usb:VVVV:PPPP` spec
      # works here too and picks the mono node automatically:
      #
      #   cameras.ir = "usb:VVVV:PPPP";
      #
      # Gaze ships per-device IR emitter profiles keyed by vendor:product, so
      # leave `emitter_enabled` off unless the new camera has one.
      #
      # Other tuning knobs:
      #
      #   security.level = "high";   # ResNet50 + SCRFD-10G, threshold 0.5.
      #                              # More accurate, noticeably slower on a
      #                              # dual-core 7500U. Default is "medium".
      #
      #   storage.encrypt_templates = true;
      #                              # Seals templates to the TPM. datum has
      #                              # /dev/tpmrm0 and already boots through
      #                              # lanzaboote, so this is worth turning on
      #                              # once face auth works — but bring it up
      #                              # afterwards, not during, so a sealing
      #                              # failure isn't confused for a camera one.
    };
  };

  # Restart gazed when its config changes.
  #
  # The upstream module sets no restartTriggers, so a rebuild rewrites
  # /etc/gaze/config.toml while the daemon keeps serving whatever it parsed at
  # startup. That bit hard on 2026-08-23: the camera pin below landed in the
  # file, `gaze doctor` (a separate process, reading from disk) reported it
  # correctly, but the running daemon still held rgb = "primary" and kept
  # opening a bare `pipewiresrc` — which resolved to the broken internal
  # camera, fired its IR emitters, and timed out after 5s with no face. The
  # symptom points at the camera rather than at staleness, so it is worth
  # keeping this wired up.
  #
  # This reads environment.etc, which the upstream module only populates when
  # mutableConfig = false (set above). Revisit if that is ever flipped back:
  # under mutableConfig = true the file is seeded via tmpfiles instead and this
  # reference would not resolve.
  systemd.services.gazed.restartTriggers = [
    config.environment.etc."gaze/config.toml".source
  ];

  # COSMIC uses one PAM service, "cosmic-greeter", for both the greetd login
  # screen and the session lock screen, so this single line covers both. It is
  # not in upstream's defaults, so it needs saying explicitly.
  #
  # Whenever this is on, pam_unix stays behind the gaze rule: the module
  # inserts face auth as `sufficient` ahead of pam_unix, so a password remains
  # a working fallback whenever the camera doesn't cooperate.
  security.pam.services.cosmic-greeter.gaze.enable = activeInAuthStack;
}
