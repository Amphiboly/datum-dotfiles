# home/modules/unix-tools/claude-code.nix
#
# Generic — no identity/auth here. Each user runs their own `claude` login
# with their own API access; this just installs the binary.
#
# Each user provides a claude-code-<user>.nix
#
{pkgs, ...}: {
  home.packages = with pkgs; [
    claude-code
    mcp-nixos
  ];
}
