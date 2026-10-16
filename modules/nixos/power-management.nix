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
      # TLP's three profiles use the _AC (performance), _BAT (balanced) and
      # _SAV (power-saver) settings. datum is nearly always on AC, so the
      # profile doesn't follow the power source: it boots in performance and
      # stays there, and balanced/power-saver are picked by hand (panel
      # power-profile switch via tlp-pd, or `tlp balanced` / `tlp
      # power-saver`).
      TLP_AUTO_SWITCH = 0;
      TLP_PROFILE_DEFAULT = "PRF";

      # Turbo: always allowed in performance, allowed in balanced (where the
      # "power" EPP below keeps it to bursts), off in power-saver. TLP has no
      # default here and leaves the kernel's setting alone unless told.
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      CPU_BOOST_ON_SAV = 0;

      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;

      # Keep USB autosuspend away from the built-in RGB+IR camera (HP Wide
      # Vision FHD, 0408:5251), which Gaze depends on (facial-auth.nix).
      # Insurance, not a known fault: the previous datum hardware's camera
      # broke after a suspend/resume on 2026-08-14 (its firmware stopped
      # loading; see commit c2c5199), and power management was a suspect,
      # never a proven cause. Its IDs (064e:3401, 1bcf:0b09) were listed here
      # until the 2026-10-12 hardware swap.
      USB_DENYLIST = "0408:5251";
    };
  };
}
