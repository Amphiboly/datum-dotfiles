# modules/nixos/users/root.nix
{...}: {
  users.users.root.initialPassword = "nix";
}
