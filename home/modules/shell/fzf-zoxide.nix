# home/modules/shell/fzf-zoxide.nix
{pkgs, ...}: {
  home.sessionVariables = {
    _ZO_DATA_DIR = "$HOME/.local/share/zoxide";
    # bat by store path, like fd in zsh-rik.nix, so this module doesn't
    # depend on cli-utils.nix putting it on PATH.
    _FZF_PREVIEW_CMD = "${pkgs.bat}/bin/bat --color=always --style=plain,numbers --line-range=:500 {}";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
