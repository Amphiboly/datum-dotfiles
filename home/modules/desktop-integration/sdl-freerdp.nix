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
#
# Launchers go through sdl-freerdp-new-workspace, which opens the session on
# an empty workspace under Umbriel. Umbriel's window rules can't do that
# themselves: default_workspace only takes a fixed position or an existing
# name. Dynamic workspaces always keep one empty workspace last on each
# output, so the wrapper switches to that one and the window opens there.
# Outside Umbriel (e.g. COSMIC) `umbriel workspaces` fails and it just runs
# sdl-freerdp. Fullscreen comes from the window rule in umbriel.toml.
{pkgs, ...}: let
  newWorkspace = pkgs.writeShellApplication {
    name = "sdl-freerdp-new-workspace";
    # umbriel and sdl-freerdp are system packages, found via PATH.
    runtimeInputs = [pkgs.gawk];
    text = ''
      # Lines look like "* eDP-1: 2 [scrolling] (focused)".
      target=$(umbriel workspaces 2>/dev/null | awk '
        { line = $0; sub(/^[* ] /, "", line); split(line, f, " ")
          out = f[1]; sub(/:$/, "", out) }
        / \(focused\)$/ { focused = out }
        { last[out] = f[2] }
        END { if (focused != "") print last[focused] "/" focused }
      ') || true
      if [ -n "$target" ]; then
        umbriel msg "workspace-switch:$target" >/dev/null || true
      fi
      exec sdl-freerdp "$@"
    '';
  };
in {
  home.packages = [
    newWorkspace
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
      exec = "sdl-freerdp-new-workspace %f";
      icon = "network-server";
      mimeType = ["application/x-rdp"];
      noDisplay = true;
    };
    mimeApps.defaultApplications."application/x-rdp" = ["sdl-freerdp.desktop"];
  };
}
