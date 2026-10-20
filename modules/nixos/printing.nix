# modules/nixos/printing.nix
{pkgs, ...}: {
  services.printing = {
    enable = true;

    # Injects the target compilation driver modules straight into the local CUPS backend loop
    drivers = with pkgs; [
      brlaser # Supports Brother MFC and HL layout frameworks natively
      hplipWithPlugin # Supports HP Color LaserJet print pipelines via proprietary hooks
    ];
  };

  # LOCAL NETWORK DISCOVERY AGENTS (AVAHI / MDNS CONFIGURATIONS)
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enables local resolution of '.local' network paths
    openFirewall = true; # Opens ports natively to prevent firewall block drops
  };

  # DOCUMENT SCANNING SUPPORT PLATFORM (SANE ENGINE)
  hardware.sane = {
    enable = true;
    extraBackends = [pkgs.sane-airscan]; # Enables driverless network scanning profiles
  };
}
