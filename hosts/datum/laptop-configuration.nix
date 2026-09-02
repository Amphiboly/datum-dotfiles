# ~/Projects/datum-config/laptop-configuration.nix
{pkgs, ...}: {
  # 1. HARDWARE ACCELERATION PIPELINES (PHYSICAL LAPTOP TARGET ONLY)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # 2. INTEL SYSTEM ENVIRONMENT TUNING VARIABLES
  environment.variables = {
    VDPAU_DRIVER = "va_gl";
    LIBVA_DRIVER_NAME = "iHD";
  };

  # Use compressed virtual swap up to 6.08GB
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 38;
  };

  # Automatically set performance level based on battery/ac
  services.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";
      };
      battery = {
        governor = "powersave";
        turbo = "never";
      };
    };
  };

  # Auto-nice configurations
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # This machine's state version
  system.stateVersion = "26.05";
}
