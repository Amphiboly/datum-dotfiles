# home/modules/unix-tools/nix-index.nix
#
# comma (`, cowsay hi`) and command-not-found, both backed by the prebuilt
# database from the nix-index-database flake input instead of a local
# `nix-index` run (about ten minutes, and stale from then on). Every
# `nix flake update` moves the database along with everything else.
#
# How the pieces fit:
#   - comma finds which package provides a command with nix-locate, which
#     reads a nix-index database. Plain `pkgs.comma` looks in
#     ~/.cache/nix-index and fails when nothing is there. The module's
#     `comma-with-db` wrapper points it at the database in the store, so
#     comma is NOT also listed in cli-utils.nix: the two would collide on
#     bin/,.
#   - When several packages provide a command (`sl` is sl, sapling and
#     femtolisp), comma asks once via fzy and remembers the pick in
#     ~/.local/state/comma/choices; later runs, even with -a, reuse it
#     without asking. `, -d <cmd>` forgets it and asks again, `, -e` clears
#     every pick, and `, -p <cmd>` lists the candidates without running.
#   - Importing the module sets programs.nix-index.enable (mkDefault). That
#     installs nix-locate against the same database and hooks zsh's
#     command_not_found_handler, so a missing command prints the package
#     that has it. It also symlinks the database into ~/.cache/nix-index,
#     for anything that looks there.
#   - The NixOS command-not-found handler is off (system-environment.nix).
#     It reads the channel's programs.sqlite, which doesn't exist on a
#     flake-only system.
{inputs, ...}: {
  imports = [inputs.nix-index-database.homeModules.nix-index];

  programs.nix-index-database.comma.enable = true;
}
