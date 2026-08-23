# modules/nixos/power-management.nix
{...}: {
  # Block the default desktop power module to clear system locks
  services.power-profiles-daemon.enable = false;

  # Enable the core TLP configuration profile
  services.tlp = {
    enable = true;

    pd.enable = true;

    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;

      # Keep USB autosuspend away from the webcam. On 2026-08-14 the module
      # stopped enumerating as an HP TrueVision FHD RGB-IR (064e:3401) and has
      # come up as the bare SunplusIT controller (1bcf:0b09) ever since — it is
      # booting from ROM instead of loading its HP firmware. The breakage
      # followed a suspend/resume, though 88 earlier suspends were harmless, so
      # power management is a suspect rather than a proven cause. This is cheap
      # insurance either way.
      #
      # Both IDs are listed deliberately: 064e:3401 protects the camera once
      # it's recovered, and 1bcf:0b09 protects it in the state it is in today.
      # TLP matches these as a space-separated word list, so a stale entry
      # simply never matches and costs nothing.
      USB_DENYLIST = "064e:3401 1bcf:0b09";
    };
  };
}
