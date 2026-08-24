# home/modules/shell/zsh-guest.nix
#
# Guest's preferences: deliberately minimal, no assumptions about tools
# beyond what guest actually has installed. Enablement lives in zsh.nix.
_: {
  programs.zsh.shellAliases = {
    ls = "ls --color=auto";
  };
}
