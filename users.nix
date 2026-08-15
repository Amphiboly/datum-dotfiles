# ~/Projects/datum-config/users.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Structural requirement: Generates system-wide /etc/zshrc global paths
  # This resolves the PATH assertion failure for users using Zsh
  programs.zsh.enable = true;

  # =======================================================================
  # ADMINISTRATIVE USER ACCOUNT (RIK)
  # =======================================================================
  users.users.rik = {
    isNormalUser = true;
    group = "rik";
    description = "Rik";
    extraGroups = ["wheel" "networkmanager" "video" "input" "audio"];
    hashedPasswordFile = config.sops.secrets.rik-password-hash.path;
    shell = pkgs.zsh;
  };

  # =======================================================================
  # UNPRIVILEGED GUEST USER ACCOUNT (GUEST)
  # =======================================================================
  users.users.guest = {
    isNormalUser = true;
    group = "guest";
    description = "Guest User";
    # No administrative wheel group to enforce security bounds
    extraGroups = ["networkmanager" "video" "audio"];
    initialPassword = "guest";
    shell = pkgs.zsh;
  };

  users.mutableUsers = true;

  # Explicit primary groups mapping
  users.groups.rik = {};
  users.groups.guest = {};

  # Mandatory path structures setup
  systemd.tmpfiles.rules = [
    "d /home/rik 0755 rik rik -"
    "f /home/rik/.zshrc 0644 rik rik - # Silenced by NixOS"

    "d /home/guest 0755 guest guest -"
    "f /home/guest/.zshrc 0644 guest guest - # Silenced by NixOS"
  ];
}
