# modules/nixos/ssh.nix
_: {
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
}
