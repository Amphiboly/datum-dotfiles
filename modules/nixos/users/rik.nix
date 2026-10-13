# modules/nixos/users/rik.nix
#
# Single source of truth for this account — previously split (with
# overlapping, redundant fields) across the root users.nix and
# configuration.nix.
{
  config,
  pkgs,
  ...
}: {
  users.users.rik = {
    isNormalUser = true;
    # Pinned: unpinned, NixOS allocates UIDs in creation order, and the
    # 2026-10-13 reinstall gave guest 1000 and rik 1001. Old rustic and
    # btrbk snapshots, and filesystems.nix's uid=1000 on the backup share,
    # all assume rik is 1000. With mutableUsers, changing this does not
    # renumber an existing account; that takes usermod (laptop-swap.md).
    uid = 1000;
    group = "rik";
    description = "Rik";
    extraGroups = ["wheel" "networkmanager" "video" "input" "audio" "render"];
    hashedPasswordFile = config.sops.secrets."rik-password-hash".path;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtSxcpUnDPA5EfZ0KmlDAjg7RzgqNoujzqOoQtQGuK4 rik@ambiguous"
    ];
  };

  # Pinned to what the 2026-10-13 reinstall allocated (from the system range,
  # since the group sets no gid), so a future reinstall can't shuffle it.
  users.groups.rik.gid = 986;

  systemd.tmpfiles.rules = [
    "d /home/rik 0755 rik rik -"
    "f /home/rik/.zshrc 0644 rik rik - # Silenced by NixOS"
  ];
}
