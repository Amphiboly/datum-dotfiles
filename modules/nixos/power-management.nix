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
    };
  };
}
