# ~/Projects/datum-config/users.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.rik = {
    isNormalUser = true;
    group = "rik";
    description = "Rik";
    extraGroups = ["wheel" "networkmanager" "video" "input"];
    hashedPasswordFile = config.sops.secrets.rik-password-hash.path;
    shell = pkgs.zsh;
  };
  users.mutableUsers = true;

  users.groups.rik = {};

  systemd.tmpfiles.rules = [
    "d /home/rik 0755 rik rik -"
    "f /home/rik/.zshrc 0644 rik rik - # Silenced by NixOS"
  ];
}
