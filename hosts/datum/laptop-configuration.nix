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

  # This machine's state version — belongs with host-identity files like
  # this one, which will move under hosts/datum/ in a later pass.
  system.stateVersion = "26.05";
}
