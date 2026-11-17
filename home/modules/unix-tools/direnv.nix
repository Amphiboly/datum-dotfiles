# home/modules/unix-tools/direnv.nix
#
# direnv loads a project's environment on cd into its folder and unloads
# it on the way out, driven by an .envrc there; `direnv allow` once per
# .envrc (and again after each edit) before it runs. nix-direnv supplies
# `use flake`/`use nix` for .envrc and caches the result in .direnv/, so
# entering a folder is instant until flake.nix or flake.lock changes; the
# cache also keeps the shell's store paths alive across garbage
# collection. Syncthing ignores .direnv (syncthing-rik.nix).
#
# The zsh hook comes from Home Manager's default shell integration.
_: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
