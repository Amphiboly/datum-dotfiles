# home/modules/unix-tools/claude-code.nix
#
# Generic — no identity/auth here. Each user runs their own `claude` login
# with their own API access; this just installs the binary.
#
# Each user provides a claude-code-<user>.nix
#
{
  pkgs,
  inputs,
  ...
}: {
  home.packages = [
    pkgs.claude-code
    # TEMPORARY pin, see the nixpkgs-mcp input in flake.nix; back to
    # `pkgs.mcp-nixos` once fastmcp works with mcp 2.x again.
    inputs.nixpkgs-mcp.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mcp-nixos
  ];
}
