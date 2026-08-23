# modules/nixos/facial-auth.nix
#
# Face unlock via Gaze (https://gaze.gundulabs.com). Upstream ships a proper
# NixOS module — daemon, D-Bus/polkit policy, PAM wiring — so this file only
# carries datum-specific policy: which PAM stacks get a face factor, and how
# strict the matcher is.
#
# Pairs with inputs.gaze.nixosModules.default, imported in hosts/datum.
#
# HARDWARE CAVEAT: as of 2026-08-22 datum's camera cannot do face auth, which
# is why `activeInAuthStack` below is false. The daemon is still built and run
# so the stack stays exercised and `gaze doctor` works; only the PAM wiring is
# withheld.
#
# The real hardware is an HP TrueVision FHD RGB-IR (USB 064e:3401), exactly
# what face auth wants, and it worked on this machine on this kernel. The
# journal (which begins at the 2026-07-13 install) shows 60 clean enumerations
# up to 2026-08-14 14:57:34. By 15:59:22 the same hardwired port (1-5) was
# enumerating a generic SunplusIT SPCA2085 (1bcf:0b09) offering one solitary
# 160x120 YUY2 mode and no IR stream — the bare Sunplus controller default,
# i.e. the module is booting from ROM instead of loading its HP firmware.
#
# Ruled out since, each with direct evidence: driver and kernel (the stub is
# in the raw USB descriptor, below uvcvideo), uvcvideo quirks (a modprobe
# option cannot change a VID:PID), a kernel regression (it worked and broke on
# 7.1.8), an intermittent load (a full port power-cycle re-enumerated it
# unchanged), EC/residual power state (a 4.5-minute drain with AC removed),
# and every relevant BIOS setting.
#
# Leading hypothesis is now physical: the battery was replaced in June 2026,
# and a marginally seated display/camera flex connector would brown the module
# out partway through loading firmware from its SPI flash, landing it in ROM
# fallback. That fits both the weeks of correct operation afterwards and the
# fact that a clean power-on never recovers it. Reseat that connector before
# assuming the module is dead.
#
# So `cameras.ir` is unset below only because there is no IR node to point it
# at today, NOT because the machine lacks one.
{lib, ...}: let
  # The single switch for whether face auth actually participates in
  # authentication. False builds and runs everything but keeps pam_gaze out of
  # every PAM stack, so `sudo` and the lock screen behave exactly as they do
  # without this module — no stall while Gaze burns liveness frames on a
  # camera that cannot enroll a face.
  #
  # Flip to true once `cat /sys/bus/usb/devices/1-5/idVendor` reports 064e.
  activeInAuthStack = false;
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
      # While the camera is RGB-only, this model is the sole thing between a
      # face match and a photograph held up to the lens, so leave it on. 0.8 is
      # upstream's default; raise it toward 0.95 to trade convenience for
      # strictness. Worth keeping on even after IR comes back.
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

      # ONCE THE 064e:3401 CAMERA IS BACK, add its infrared node here. IR is
      # the real anti-spoofing win: it sees warm skin rather than a screen or
      # a print, and it works in the dark. Find the node with `gaze doctor`
      # (or `v4l2-ctl --list-devices`) — on an RGB-IR module the IR stream is
      # usually the second capture node and reports GREY/Y8 rather than YUY2:
      #
      #   cameras.ir = "/dev/video2";
      #
      # `cameras.rgb` should stay at its "primary" default, and note that a
      # pinned RGB value must be a PipeWire node identity, not a device path.
      #
      # Gaze ships per-device IR emitter profiles keyed by vendor:product, and
      # there is no 064e-3401 profile upstream, so leave `emitter_enabled` off
      # until you can confirm the IR stream is usable on ambient illumination.
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

  # COSMIC uses one PAM service, "cosmic-greeter", for both the greetd login
  # screen and the session lock screen, so this single line covers both. It is
  # not in upstream's defaults, so it needs saying explicitly.
  #
  # Whenever this is on, pam_unix stays behind the gaze rule: the module
  # inserts face auth as `sufficient` ahead of pam_unix, so a password remains
  # a working fallback whenever the camera doesn't cooperate.
  security.pam.services.cosmic-greeter.gaze.enable = activeInAuthStack;
}
