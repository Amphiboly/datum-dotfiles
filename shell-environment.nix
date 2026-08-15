# shell-environment.nix
{pkgs, ...}: {
  # Core system environments common to EVERY user session
  environment.sessionVariables = {
    # Keep hardware/graphics workarounds here
    ZED_ALLOW_EMULATED_GPU = "1";
  };

  # Universal system tools that do no harm to a guest
  environment.systemPackages = with pkgs; [
    wl-clipboard
    curl
    git
  ];
}
