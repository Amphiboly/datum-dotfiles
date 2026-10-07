# home/modules/desktop-integration/sdl-freerdp.nix
#
# Opens .rdp files with sdl-freerdp. The binary itself is installed
# system-wide by modules/nixos/remote-desktop.nix.
#
# shared-mime-info has no type for .rdp, so this defines application/x-rdp.
# The definition ships as a package rather than as an xdg.dataFile in
# ~/.local/share/mime/packages: home-manager compiles share/mime from the
# profile, but nothing runs update-mime-database on ~/.local/share/mime, so
# a bare XML file there is never read. (That is how Remmina's HM module did
# it, and .rdp files stayed text/plain.)
{pkgs, ...}: {
  home.packages = [
    (pkgs.writeTextDir "share/mime/packages/application-x-rdp.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
        <mime-type type="application/x-rdp">
          <comment>RDP connection file</comment>
          <glob pattern="*.rdp"/>
        </mime-type>
      </mime-info>
    '')
  ];

  xdg = {
    # Handler only: run without a file, sdl-freerdp has nothing to connect
    # to, so keep it out of the launcher.
    desktopEntries.sdl-freerdp = {
      name = "FreeRDP";
      exec = "sdl-freerdp %f";
      icon = "network-server";
      mimeType = ["application/x-rdp"];
      noDisplay = true;
    };
    mimeApps.defaultApplications."application/x-rdp" = ["sdl-freerdp.desktop"];
  };
}
