# modules/nixos/ssh.nix
_: {
  services.openssh = {
    enable = true;
    settings = {
      # Keys only. PasswordAuthentication alone doesn't do it: NixOS leaves
      # KbdInteractiveAuthentication on, and with UsePAM that still accepts
      # passwords (it did until 2026-10-13, so guest's public initial
      # password in guest.nix was good for SSH too).
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
