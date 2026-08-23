# home/modules/desktop-integration/onepassword.nix
#
# Start 1Password at login, minimised to the tray.
#
# The 1Password SSH agent is not a daemon of its own: it lives inside the
# desktop app and only listens on ~/.1password/agent.sock while that app is
# running. The socket file survives the app exiting, so a stale one sits there
# looking healthy while every connection to it is refused — which is exactly
# how deploy.sh failed on 2026-08-23, with ssh falling back to the (now
# deleted) ~/.ssh/id_* files and thus to no keys at all.
#
# Autostarting closes that gap: the agent is up before anything wants it.
#
# The package itself comes from programs._1password-gui at the system level
# (see modules/nixos/onepassword.nix), so Exec deliberately names the bare
# binary and picks up the polkit-wrapped build from the session PATH rather
# than pinning an unwrapped store path.
{...}: {
  xdg.configFile."autostart/1password.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=1Password
    Comment=Start 1Password minimised so its SSH agent socket is available
    Exec=1password --silent
    Terminal=false
    X-GNOME-Autostart-enabled=true
  '';

  # With gcr-ssh-agent switched off system-side, nothing else sets this, so
  # tools that consult SSH_AUTH_SOCK instead of parsing ssh_config find the
  # right agent. `ssh` does not depend on this — IdentityAgent in
  # ~/.ssh/config already covers it — this is for everything else.
  home.sessionVariables.SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
}
