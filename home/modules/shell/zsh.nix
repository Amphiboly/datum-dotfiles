# home/modules/shell/zsh.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    zellij
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
    shellAliases = {
      cat = "bat";
      ls = "eza --icons --color=auto --color-scale=all --icons=auto";
      la = "eza --icons --color=auto --color-scale=all --icons=auto -la";
      ll = "eza --icons --color=auto --color-scale=all --icons=auto -ll";
      lm = "eza --icons --color=auto --color-scale=all --icons=auto -ll -s modified";
      tree = "eza --icons --tree";
      ffetch = "fastfetch -c all.jsonc";
      grep = "rg --color=auto";
      diff = "diff --color=auto";
      ollama = "OLLAMA_NUM_PARALLEL=1 ollama";
    };
    initContent = ''
      if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi

      export FZF_DEFAULT_COMMAND="${pkgs.fd}/bin/fd --type f --hidden --strip-cwd-prefix"
      export FZF_DEFAULT_OPTS="--height=60% --layout=reverse --border=rounded --prompt=\"  \" --pointer=\"  \" --preview-window=right:65%:wrap:border-left"

      bindkey -v
      export KEYTIMEOUT=1
      bindkey '^?' backward-delete-char
      bindkey '^H' backward-delete-char
      bindkey '^w' backward-kill-word
      bindkey '^r' history-incremental-search-backward

      # ---------------------------------------------------------
      #   Custom Shell Functions & Initializations
      # ---------------------------------------------------------

      # 1. Custom Yazi traversal function
      y() {
         local tmp
         tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
         command yazi "$@" --cwd-file="$tmp"
         if [ -f "$tmp" ]; then
             cwd="$(cat "$tmp")"
             if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [ -d "$cwd" ]; then
                 builtin cd -- "$cwd"
             fi
             rm -f -- "$tmp"
         fi
      }

      # 2. Workspace Project Aware Helix launch
      hx() {
          local project_root
          project_root=$(git rev-parse --show-toplevel 2>/dev/null || \
                         find . -maxdepth 5 -name "flake.nix" -exec dirname {} \; 2>/dev/null | head -n 1)

          if [ -n "$project_root" ] && [ $# -eq 0 ]; then
              (cd "$project_root" && command hx .)
          else
              command hx "$@"
          fi
      }

      # 3. Inject zoxide shell initialization
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

      # 4. Fastfetch environment detection logo engine
      fastfetch_dynamic() {
          if [ -f /etc/fedora-release ]; then
              export FF_OS_ICON=""
              export FF_OS_COLOR="blue"
              export FF_LOGO="$HOME/.config/fastfetch/logos/Fedora.png"
          elif ${pkgs.gnugrep}/bin/grep -q "NixOS" /etc/os-release 2>/dev/null; then
             export FF_LOGO="${../../../assets/NixOS.png}"
          else
              export FF_OS_ICON=""
              export FF_OS_COLOR="green"
              export FF_LOGO=""
          fi
          command fastfetch --logo "$FF_LOGO" --logo-type kitty --logo-width 28 --logo-height 12 "$@"
      }

      if [[ -o interactive ]]; then
          alias fastfetch="fastfetch_dynamic"
          fastfetch_dynamic
      fi

      # Silence the new user configuration prompt for empty home directories
      [[ -f ~/.zshrc || -f ~/.zprofile ]] || export ZDOTDIR="/etc"
      # AUTOMATIC WORKSPACE PERSISTENCE (ZELLIJ INTERACTIVE INITIALIZATION)
      # 1. Ensure the shell is interactive and not already inside an active Zellij workspace
      if [[ -o interactive && -z "$ZELLIJ" && "$TERM_PROGRAM" != "vscode" ]]; then
          # 2. Check if a master session already exists to hook back into
          if zellij list-sessions 2>/dev/null | grep -q "default"; then
              exec zellij attach "default"
          else
              # 3. Create a fresh session and force Locked mode to prevent key collisions
              exec zellij options --default-mode locked --theme dracula --simplified-ui true
          fi
      fi    '';
  };
}
