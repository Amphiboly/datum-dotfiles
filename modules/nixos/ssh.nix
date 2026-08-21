# modules/nixos/ssh.nix
{...}: {
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
}
