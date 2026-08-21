# home/modules/shell/fzf-zoxide.nix
{...}: {
  home.sessionVariables = {
    _ZO_DATA_DIR = "$HOME/.local/share/zoxide";
    _FZF_PREVIEW_CMD = "bat --color=always --style=plain,numbers --line-range=:500 {}";
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
