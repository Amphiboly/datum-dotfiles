# modules/nixos/users/guest.nix
{pkgs, ...}: {
  users.users.guest = {
    isNormalUser = true;
    group = "guest";
    description = "Guest User";
    # Essential desktop groups without administrative access:
    extraGroups = ["networkmanager" "video" "audio"];
    # Sets an initial default password (e.g. "guest") so they can log in
    initialPassword = "guest";
    shell = pkgs.zsh;
  };

  users.groups.guest = {};

  systemd.tmpfiles.rules = [
    "d /home/guest 0755 guest guest -"
    "f /home/guest/.zshrc 0644 guest guest - # Silenced by NixOS"
  ];
}
