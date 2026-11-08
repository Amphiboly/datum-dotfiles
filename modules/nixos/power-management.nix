# modules/nixos/power-management.nix
#
# Noctalia's NixOS module offers `programs.noctalia.recommendedServices`,
# which turns on NetworkManager, Bluetooth, UPower, and power-profiles-daemon
# in one go. Deliberately not used: NetworkManager/Bluetooth/UPower are
# already handled by networking.nix/bluetooth.nix (and UPower transitively),
# and recommendedServices would re-enable power-profiles-daemon, fighting
# TLP for control of the CPU governor below. inputs.noctalia.nixosModules
# stays unimported system-wide for this reason -- Noctalia here is purely the
# per-user Home Manager shell (see home/modules/desktop-integration/).
{config, ...}: {
  services = {
    # Block the default desktop power module to clear system locks
    power-profiles-daemon.enable = false;

    # Enable the core TLP configuration profile
    tlp = {
      enable = true;

      pd.enable = true;

      settings = {
        # TLP's three profiles use the _AC (performance), _BAT (balanced) and
        # _SAV (power-saver) settings. datum is nearly always on AC, so the
        # profile doesn't follow the power source: it boots in performance
        # and stays there, and balanced/power-saver are picked by hand (panel
        # power-profile switch via tlp-pd, or `tlp balanced` / `tlp
        # power-saver`).
        TLP_AUTO_SWITCH = 0;
        TLP_PROFILE_DEFAULT = "PRF";

        # Turbo: always allowed in performance, allowed in balanced (where
        # the "power" EPP below keeps it to bursts), off in power-saver. TLP
        # has no default here and leaves the kernel's setting alone unless
        # told.
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 1;
        CPU_BOOST_ON_SAV = 0;

        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # No START/STOP_CHARGE_THRESH_BAT0: this HP's ACPI battery exposes no
        # charge_control_*_threshold files (checked 2026-10-16, after the
        # battery exchange), so TLP has nothing to write them to and the
        # battery always charges to 100%.

        # Keep USB autosuspend away from the built-in RGB+IR camera (HP Wide
        # Vision FHD, 0408:5251), which Gaze depends on (facial-auth.nix).
        # Insurance, not a known fault: the previous datum hardware's camera
        # broke after a suspend/resume on 2026-08-14 (its firmware stopped
        # loading; see commit c2c5199), and power management was a suspect,
        # never a proven cause. Its IDs (064e:3401, 1bcf:0b09) were listed
        # here until the 2026-10-12 hardware swap.
        USB_DENYLIST = "0408:5251";
      };
    };

    # Critical-battery policy. upower itself is enabled in
    # desktop/shared-services.nix; only the thresholds are set here. The
    # defaults (warn at 5%, act at 2%) are too late for this pack: on the
    # BTI YB06XL's first full discharge (2026-11-08) its protection circuit
    # cut the power at a reported 3% (8.96 V under a 2.9 A load), before
    # upower's action fired. See KNOWN-ISSUES.md section 1. 5% leaves room
    # for the gauge being a few points high near empty, for about 20
    # minutes of runtime. The action itself stays HybridSleep, which logind
    # reports as unavailable here (no disk swap, only zram), so upower
    # falls back to PowerOff.
    upower = {
      percentageCritical = 8;
      percentageAction = 5;
    };
  };

  # upowerd reads UPower.conf only at startup, and its unit comes from the
  # package with no restart trigger, so a rebuild that changes the
  # thresholds above left the running daemon on the old ones (seen
  # 2026-11-08). This makes switch-to-configuration restart it whenever
  # the generated file changes. Noctalia's battery indicator blanks for a
  # moment during the restart.
  systemd.services.upower.restartTriggers = [
    config.environment.etc."UPower/UPower.conf".source
  ];
}
