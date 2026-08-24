# home/modules/shell/zsh.nix
#
# Enablement only: completion/autosuggestion/history UX that's good for any
# user. No aliases, keybindings, or workflow functions — see zsh-rik.nix or
# zsh-guest.nix for those.
{pkgs, ...}: {
  home.packages = with pkgs; [
    zsh-completions
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch = {
      enable = true;
      searchUpKey = ["^[[A"];
      searchDownKey = ["^[[B"];
    };
    history = {
      size = 50000;
      path = "$HOME/.zsh_history";
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
    };
    initContent = ''
      if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi

      # Silence the new user configuration prompt for empty home directories
      [[ -f ~/.zshrc || -f ~/.zprofile ]] || export ZDOTDIR="/etc"
    '';
  };
}
