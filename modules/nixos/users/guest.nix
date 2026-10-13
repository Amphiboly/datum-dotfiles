# modules/nixos/users/guest.nix
{pkgs, ...}: {
  users.users.guest = {
    isNormalUser = true;
    uid = 1001; # pinned alongside rik's, see rik.nix
    group = "guest";
    description = "Guest User";
    # Essential desktop groups without administrative access:
    extraGroups = ["networkmanager" "video" "audio"];
    # A known password on purpose: this is the account anyone at the
    # keyboard may use. It only applies when the account is created
    # (mutableUsers), and SSH takes keys only (ssh.nix), so it's good at the
    # console and nowhere else.
    initialPassword = "guest";
    shell = pkgs.zsh;
  };

  users.groups.guest.gid = 993; # pinned alongside rik's, see rik.nix

  systemd.tmpfiles.rules = [
    "d /home/guest 0755 guest guest -"
    "f /home/guest/.zshrc 0644 guest guest - # Silenced by NixOS"
  ];
}
