# home/modules/shell/zsh.nix
#
# Enablement only: completion/autosuggestion/history UX that's good for any
# user. No aliases, keybindings, or workflow functions — see zsh-rik.nix or
# zsh-guest.nix for those.
{pkgs, ...}: {
  home.packages = with pkgs; [
    zsh-completions
  ];

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    # following lets fzf have ctrl-r, atuin will use Up-Arrow
    flags = ["--disable-ctrl-r"];
    settings = {
      filter_mode_shell_up_key_binding = "global"; # or host, or session
      style = "full"; # or compact for one-line per
      inline_height = 20;
      auto_sync = false;
      update_check = false;
      sync_address = "http://localhost:0"; # dummy address to satisfy
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    ## Atuin over-rides these, but leave in so atuin is easier to remove.
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
