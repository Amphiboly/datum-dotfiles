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
_: {
  # Block the default desktop power module to clear system locks
  services.power-profiles-daemon.enable = false;

  # As of the 2026-09-16 nixpkgs bump, services.desktopManager.cosmic sets
  # `hardware.system76.power-daemon.enable = mkDefault (!power-profiles-daemon
  # && !tuned)`, on the assumption that without one of those two you must
  # want system76-power as the org.freedesktop.UPower.PowerProfiles provider.
  # It doesn't know about TLP's own `pd.enable` shim below, which already
  # claims that D-Bus name -- so system76-power crash-loops fighting TLP for
  # it, and it's actively wrong hardware detection anyway (this is an HP, not
  # a System76 machine; "does not have switchable graphics" in its own log).
  # `mkDefault` means a plain assignment here wins over it.
  hardware.system76.power-daemon.enable = false;

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
