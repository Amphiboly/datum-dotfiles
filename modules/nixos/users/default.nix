# modules/nixos/users/default.nix
#
# Cross-cutting user-management settings, not specific to any one account.
{...}: {
  # Structural requirement: Generates system-wide /etc/zshrc global paths
  # This resolves the PATH assertion failure for users using Zsh
  programs.zsh.enable = true;

  users.mutableUsers = true;
}
