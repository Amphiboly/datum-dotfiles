# home/modules/shell/zsh-rik.nix
#
# Preferences: aliases, vi-mode keybindings, workflow functions, and the
# zellij auto-attach hijack. Enablement lives in zsh.nix.
#
# Note: the manual `zoxide init zsh` eval that used to live here is gone —
# it was a redundant double-init; programs.zoxide.enableZshIntegration
# (fzf-zoxide.nix) already sources it.
{pkgs, ...}: {
  programs.zsh = {
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

      # 3. Fastfetch environment detection logo engine
      fastfetch_dynamic() {
         export FF_LOGO="${../../../assets/NixOS.png}"
         command fastfetch --logo "$FF_LOGO" --logo-type kitty --logo-width 28 --logo-height 12 "$@"
      }

      if [[ -o interactive ]]; then
          alias fastfetch="fastfetch_dynamic"
          fastfetch_dynamic
      fi

      # Commented out 2026-08-24 -- kitty should be sufficient
      # # AUTOMATIC WORKSPACE PERSISTENCE (ZELLIJ INTERACTIVE INITIALIZATION)
      # # 1. Ensure the shell is interactive and not already inside an active Zellij workspace
      # if [[ -o interactive && -z "$ZELLIJ" && "$TERM_PROGRAM" != "vscode" ]]; then
      #     # 2. Check if a master session already exists to hook back into
      #     if zellij list-sessions 2>/dev/null | grep -q "default"; then
      #         exec zellij attach "default"
      #     else
      #         # 3. Create a fresh session and force Locked mode to prevent key collisions
      #         exec zellij options --default-mode locked --theme dracula --simplified-ui true
      #     fi
      # fi
    '';
  };
}
