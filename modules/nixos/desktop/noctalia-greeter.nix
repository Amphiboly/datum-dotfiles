# modules/nixos/desktop/noctalia-greeter.nix
#
# The login screen: noctalia-greeter (github:noctalia-dev/noctalia-greeter),
# a greetd greeter with its own small wlroots compositor, styled like
# Noctalia. It replaced cosmic-greeter on 2026-11-03. Package and module
# come from nixpkgs (services.displayManager.noctalia-greeter), not the
# upstream flake: same version, and cache.nixos.org has it.
#
# Face auth needs nothing here. greetd runs the PAM conversation and its
# stack is `substack login`, where facial-auth.nix puts pam_gaze ahead of
# pam_unix; the greeter only relays PAM's prompts. What it does need is
# allow_empty_password: by default it ignores Enter on an empty field, and
# it only starts PAM (greetd create_session) on a submit. With it on:
#   - Enter on an empty field starts PAM; pam_gaze checks the face and, on
#     a match, logs in with no password.
#   - On a miss pam_unix asks for the password; the greeter answers with
#     what was submitted (nothing), so that attempt fails. Typing the
#     password and pressing Enter starts PAM again, which tries the face
#     once more (~5 s) before taking the password, as on Noctalia's lock
#     screen.
# request_timeout (how long the greeter waits for each greetd reply) stays
# at its default of 60 s, well past Gaze's ~5 s.
#
# Appearance comes from Noctalia: Settings -> Security -> Noctalia Greeter
# -> Sync copies the wallpaper, palette, font and monitor layout into
# /var/lib/noctalia-greeter/sync.toml (Auto-Sync redoes it on changes).
# The helper runs as root through polkit; passwordlessSyncUsers lets rik
# run that appearance-only operation without a password prompt. Values
# set in `settings` below (greeter.toml) win over synced ones, so keep
# appearance out of it.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.displayManager.noctalia-greeter;
in {
  services.displayManager.noctalia-greeter = {
    enable = true;
    passwordlessSyncUsers = ["rik"];
    settings.auth.allow_empty_password = true;
  };

  # The greeter finds sessions in /run/current-system/sw/share/
  # wayland-sessions and $XDG_DATA_DIRS. On NixOS neither has them: the
  # session files (umbriel.desktop) are only in
  # services.displayManager.sessionData.desktops. The nixpkgs module
  # doesn't pass that (as of 2026-11-03); upstream's flake module does,
  # the same way as here. A plain assignment beats the module's mkDefault.
  services.greetd.settings.default_session.command =
    "${lib.getExe' pkgs.coreutils "env"} "
    + "XDG_DATA_DIRS=${config.services.displayManager.sessionData.desktops}/share "
    + "${lib.getExe' cfg.package "noctalia-greeter-session"}";
}
