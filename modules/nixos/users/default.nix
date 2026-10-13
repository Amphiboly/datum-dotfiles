# modules/nixos/users/default.nix
#
# Cross-cutting user-management settings, not specific to any one account.
_: {
  # Structural requirement: Generates system-wide /etc/zshrc global paths
  # This resolves the PATH assertion failure for users using Zsh
  programs.zsh.enable = true;

  # Mutable on purpose: users change their own passwords with `passwd`,
  # without a rebuild (the multi-user rule in CLAUDE.md). The cost is that
  # declared passwords (initialPassword, hashedPasswordFile) only apply when
  # an account is created, never again. See rik.nix for how that bit.
  users.mutableUsers = true;
}
