# home/modules/desktop-integration/sdl-freerdp-rik.nix
#
# Hotkeys for sdl-freerdp (the SDL3 FreeRDP client). It has no floatbar —
# /floatbar is parsed by the shared FreeRDP cmdline code but ignored by the
# SDL client — so window control is keyboard-only. Every hotkey is
# SDL_KeyModMask + one key; options and their defaults are listed under
# CONFIGURATION FILE in sdl-freerdp(1).
#
# Also a connection profile and launcher for 5CD-RACK. The name resolves
# through Tailscale MagicDNS; RDP to its LAN address is firewalled.
{config, ...}: let
  rackProfile = "${config.xdg.configHome}/freerdp/5cd-rack.rdp";
in {
  xdg.configFile = {
    "freerdp/sdl-freerdp.json".text = builtins.toJSON {
      # Default is Right Shift alone.
      SDL_KeyModMask = ["KMOD_LCTRL" "KMOD_LALT"];
      # Default D. Left at their defaults: Return (fullscreen), M (minimize),
      # R (resizeable), G (keyboard/mouse grab).
      SDL_Disconnect = "SDL_SCANCODE_Q";
    };

    # No password stored; sdl-freerdp prompts for it.
    "freerdp/5cd-rack.rdp".text = ''
      full address:s:5CD-RACK
      username:s:5CD-RACK\5CD
      dynamic resolution:i:1
      redirectclipboard:i:1
      desktopscalefactor:i:200
    '';
  };

  xdg.desktopEntries."5cd-rack" = {
    name = "5CD-RACK";
    genericName = "Remote Desktop";
    exec = "sdl-freerdp ${rackProfile}";
    icon = "network-server";
    categories = ["Network" "RemoteAccess"];
  };
}
