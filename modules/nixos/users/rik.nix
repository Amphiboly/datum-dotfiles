# modules/nixos/users/rik.nix
#
# Single source of truth for this account — previously split (with
# overlapping, redundant fields) across the root users.nix and
# configuration.nix.
{config, pkgs, ...}: {
  users.users.rik = {
    isNormalUser = true;
    group = "rik";
    description = "Rik";
    extraGroups = ["wheel" "networkmanager" "video" "input" "audio" "render"];
    hashedPasswordFile = config.sops.secrets."rik-password-hash".path;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtSxcpUnDPA5EfZ0KmlDAjg7RzgqNoujzqOoQtQGuK4 rik@ambiguous"
    ];
  };

  users.groups.rik = {};

  systemd.tmpfiles.rules = [
    "d /home/rik 0755 rik rik -"
    "f /home/rik/.zshrc 0644 rik rik - # Silenced by NixOS"
  ];
}
