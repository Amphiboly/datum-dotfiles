# modules/nixos/printing.nix
{pkgs, ...}: {
  services.printing = {
    enable = true;

    # Injects the target compilation driver modules straight into the local CUPS backend loop
    drivers = with pkgs; [
      brlaser # Supports Brother MFC and HL layout frameworks natively
      hplipWithPlugin # Supports HP Color LaserJet print pipelines via proprietary hooks
    ];

    # No cups-browsed (2026-11-22). It runs as root, parses printer
    # advertisements from the network, and was the way in for the 2024
    # CUPS remote-code-execution chain (CVE-2024-47176 and friends). Both
    # printers here are driverless (IPP Everywhere / AirPrint, seen via
    # Avahi), and cupsd alone turns those into temporary queues when an
    # application prints. The queues cups-browsed made (implicitclass://)
    # go with it.
    browsed.enable = false;
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
