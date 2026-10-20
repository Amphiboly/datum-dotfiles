# modules/nixos/printing.nix
{pkgs, ...}: {
  services.printing = {
    enable = true;

    # Injects the target compilation driver modules straight into the local CUPS backend loop
    drivers = with pkgs; [
      brlaser # Supports Brother MFC and HL layout frameworks natively
      # Supports HP Color LaserJet print pipelines via proprietary hooks.
      #
      # WORKAROUND (2026-10-20, nixpkgs 09063bd): buildPythonApplication now
      # defaults to __structuredAttrs = true, which turns hplip's
      # makeWrapperArgs into a bash array. Its preFixup still expands it
      # unquoted as `$makeWrapperArgs`, which yields only the first element
      # ("--prefix"), so makeCWrapper chokes on the gapps args that follow
      # ("Unknown argument .../dconf-.../gio/modules"). hplipWithPlugin is
      # unfree, so there's no cache hit to hide it. Fixed upstream by
      # NixOS/nixpkgs#575319 (hplip 3.26.6); drop this override once the
      # lock's nixpkgs has it. See KNOWN-ISSUES.md.
      (hplipWithPlugin.overrideAttrs {__structuredAttrs = false;})
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
