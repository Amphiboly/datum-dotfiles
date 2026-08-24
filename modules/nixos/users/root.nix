# modules/nixos/users/root.nix
_: {
  users.users.root.initialPassword = "nix";
}
