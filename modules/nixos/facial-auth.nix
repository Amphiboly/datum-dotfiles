# modules/nixos/facial-auth.nix
#
# Face unlock via Gaze (https://gaze.gundulabs.com). Upstream ships a proper
# NixOS module — daemon, D-Bus/polkit policy, PAM wiring — so this file only
# carries datum-specific policy: which PAM stacks get a face factor, which
# camera, and how strict the matcher is.
#
# Pairs with inputs.gaze.nixosModules.default, imported in hosts/datum.
#
# CAMERA: the 15-ch's built-in HP Wide Vision FHD module (SunplusIT,
# 0408:5251, hardwired on USB port 1-5), used for both RGB and IR since
# 2026-10-13. It is one USB device with two UVC functions:
#
#   - interface 0: colour, MJPEG only (no raw format), up to 1920x1080
#     (/dev/video0)
#   - interface 2: IR, 8-bit greyscale at 352x352 only (/dev/video2)
#
# The IR function carries Microsoft's camera extension unit (unit 7, GUID
# 0f3f95dc-2632-4c4e-92c9-a04782f43bc8, face-authentication selector 6), and
# its emitter comes up in mode 2, strobing on alternate frames, as soon as the
# IR stream starts. Measured 2026-10-13: lit frames read ~75-90 mean luma on a
# face, unlit ones ~8-9, so the default dark_luma_threshold (20) drops the
# unlit half. Gaze has no ir-profiles entry for 0408:5251 and none is needed:
# emitter_enabled stays off. (Were it on, Gaze's runtime probe would find the
# same unit 7 control and set the same mode.)
#
# IR is what makes this real anti-spoofing: a phone screen or a print shows
# nothing under IR, so it can't match an IR template. The RGB path keeps
# MiniFASNet-V2 liveness; on the IR path Gaze checks for eye movement.
#
# History: the previous datum (Spectre x360 13-ac, until 2026-10-12) had a
# built-in camera whose firmware broke on 2026-08-14 and enumerated as a
# 160x120 SPCA2085 stub, so face auth ran off an external AVerMedia CAM 313
# pinned as usb:07ca:313a. That diagnosis is in commit c2c5199 and this file's
# history; none of it applies to the 15-ch.
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

  # Explicit sources rather than the "primary" default. `usb:` and node specs
  # build a v4l2src pipeline, which works in a greeter that has no PipeWire
  # session; "primary" needs one.
  #
  # IR is pinned by USB VID:PID: Gaze picks the mono (GREY) node of the
  # matching device, wherever it lands in /dev/video* numbering.
  #
  # RGB has to be the node itself. Gaze 0.3.9 resolves `usb:` specs with a
  # GStreamer device monitor filtered to video/x-raw, and this camera's colour
  # node offers MJPEG only, so `usb:0408:5251` finds no colour node and the
  # daemon refuses with "no backing /dev/video node" (enrollment failed that
  # way on 2026-10-13; `gaze doctor` uses a different check and passes).
  # Gaze's capture pipeline itself takes image/jpeg fine. /dev/video0 is
  # stable here: the built-in camera is hardwired and probes first at boot,
  # so an external camera gets a higher number. If the numbering ever did
  # shift, the wrong camera simply fails to match and PAM falls through to the
  # password. Switch back to builtinCamera once Gaze's resolver accepts
  # MJPEG-only nodes.
  builtinCamera = "usb:0408:5251";
  builtinRgbNode = "/dev/video0";
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
      cameras = {
        rgb = builtinRgbNode;
        ir = builtinCamera;
        # parallel_capture stays at its default, "never" (RGB, then IR). The
        # two spectra are separate UVC functions here, so "auto" would stream
        # them at once and cut latency; try it once the serial setup has
        # proven itself.
      };

      # security.level stays at its default, "medium": SCRFD-500M +
      # MobileFaceNet, threshold 0.40, hybrid_policy "fallback_on_dark", i.e.
      # RGB and IR must both match unless the RGB frame is too dark, when IR
      # alone suffices. "high" (ResNet50 + SCRFD-10G, 0.50) is the next step
      # up and the quad-core i7-8550U should carry it; "maximum" demands both
      # spectra always.

      # The anti-spoof model for the RGB path. 0.8 is upstream's default;
      # raise it toward 0.95 to trade convenience for strictness.
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

      # Not yet:
      #
      #   storage.encrypt_templates = true;
      #                              # Seals templates to the TPM (/dev/tpmrm0,
      #                              # discrete Infineon). Worth turning on
      #                              # once face auth works, but separately, so
      #                              # a sealing failure isn't confused for a
      #                              # camera one. Existing templates need
      #                              # re-enrolling afterwards.
    };
  };

  # Restart gazed when its config changes.
  #
  # The upstream module sets no restartTriggers, so a rebuild rewrites
  # /etc/gaze/config.toml while the daemon keeps serving whatever it parsed at
  # startup. That bit hard on 2026-08-23: a camera pin landed in the file,
  # `gaze doctor` (a separate process, reading from disk) reported it
  # correctly, but the running daemon still held rgb = "primary" and kept
  # opening the wrong camera. The symptom points at the camera rather than at
  # staleness, so it is worth keeping this wired up.
  #
  # This reads environment.etc, which the upstream module only populates when
  # mutableConfig = false (set above). Revisit if that is ever flipped back:
  # under mutableConfig = true the file is seeded via tmpfiles instead and this
  # reference would not resolve.
  systemd.services.gazed.restartTriggers = [
    config.environment.etc."gaze/config.toml".source
  ];

  # COSMIC's login screen and lock screen use different PAM services, and
  # neither is in upstream's defaults:
  #
  #   - "cosmic-greeter" is the lock screen only.
  #   - The login screen is cosmic-greeter acting as a greetd client; greetd
  #     itself runs the PAM conversation, as service "greetd" (which pulls in
  #     the "login" stack via substack). Until 2026-10-14 this file assumed
  #     cosmic-greeter covered both, so login never had face auth.
  #
  # Whenever this is on, the password stays a fallback: the module inserts
  # face auth as `sufficient` ahead of pam_unix. In greetd's stack there is no
  # unix rule of its own, so gaze lands ahead of `substack login`; a face
  # match skips the login stack, and a miss falls through to its password
  # prompt.
  #
  # Keyring: a face login gives pam_gnome_keyring no password, so the
  # "login" keyring (Maestral's Dropbox token is in it) can't be unlocked by
  # PAM. It has a blank password instead, set by hand in Seahorse on
  # 2026-10-14, so it opens without one; LUKS and file permissions protect it
  # at rest. If it ever gets a password again, face logins leave it locked and
  # Maestral stalls or prompts.
  security.pam.services.cosmic-greeter.gaze.enable = activeInAuthStack;
  security.pam.services.greetd.gaze.enable = activeInAuthStack;
}
