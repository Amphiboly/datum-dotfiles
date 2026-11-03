# modules/nixos/desktop/cosmic-greeter.nix
#
# The login screen: cosmic-greeter, a greetd client, on its own. The COSMIC
# desktop itself went on 2026-11-03 (tag last-cosmic has it); the greeter
# stays until noctalia-greeter has been shown to work with Gaze, and then
# this file goes too. It needs no COSMIC session to run: it lists whatever
# services.displayManager.sessionPackages holds, which is just Umbriel now.
#
# Face auth at login comes through greetd's PAM stack (facial-auth.nix),
# not through anything here.
_: {
  services.displayManager.cosmic-greeter.enable = true;
}
