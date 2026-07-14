# ~/Projects/datum-config/shell.nix
{
  config,
  pkgs,
  ...
}: {
  # 1. Native FZF Configuration (Corrected for NixOS System Scope)
  programs.fzf = {
    keybindings = true; # Instantly binds Ctrl+R, Alt+C, etc.
    fuzzyCompletion = true; # Enables native tab-completions
  };

  # 2. Global Core Interactive Packages
  environment.systemPackages = with pkgs; [
    # Compile local mksecrets.sh file into a native global system command binary
    (writeScriptBin "mksecrets" (builtins.readFile ./mksecrets.sh))

    # --- Terminal Monitors & System Pagers ---
    btop
    fastfetch
    tldr
    starship

    # --- GUI Apps ---
    naps2

    # --- Modern CLI Toolchain Utilities ---
    helix
    bat
    eza
    yazi
    ripgrep
    fd
    zoxide
    fzf
    zathura # High-performance lightweight PDF reader matching text toolchains

    # --- Structural Editors & IDE Environments ---
    nixd
    tinymist
    vim-full
    zed-editor
    # Generate a permanent global binary link so 'spawn,zed' works natively []
    (runCommand "zed-cli-link" {} "mkdir -p $out/bin && ln -s ${zed-editor}/bin/zeditor $out/bin/zed")

    # --- Advanced Document & Compiling Engines ---
    # Injects the specific targeted ConTeXt layout without downloading 7GB of math books
    texlive.combined.scheme-context
    typst
    pandoc
    mdbook

    # --- Shell Configuration Plugin Layers ---
    antidote
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
  ];

  # 3. Main Zsh Declarative Module
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableGlobalCompInit = true;

    histSize = 50000;
    histFile = "$HOME/.zsh_history";
    setOptions = ["SHARE_HISTORY" "HIST_IGNORE_DUPS" "HIST_IGNORE_SPACE" "HIST_EXPIRE_DUPS_FIRST"];

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

    interactiveShellInit = ''
      # ---------------------------------------------------------
      #   FZF Global Environment Configuration Mappings
      # ---------------------------------------------------------
      export FZF_DEFAULT_COMMAND="${pkgs.fd}/bin/fd --type f --hidden --strip-cwd-prefix"
      export FZF_DEFAULT_OPTS="--height=60% --layout=reverse --border=rounded --prompt=\"  \" --pointer=\"  \" --preview-window=right:65%:wrap:border-left"

      # ---------------------------------------------------------
      #   Bypassing Antidote Downloads with Native Cached Packages
      # ---------------------------------------------------------
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

      # ---------------------------------------------------------
      #   Shell Controls & Keybindings
      # ---------------------------------------------------------
      bindkey -v
      export KEYTIMEOUT=1

      bindkey '^?' backward-delete-char
      bindkey '^H' backward-delete-char
      bindkey '^w' backward-kill-word
      bindkey '^r' history-incremental-search-backward

      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # ---------------------------------------------------------
      #   Custom Tool Infrastructure Definitions
      # ---------------------------------------------------------
      export OSFONTDIR="/run/current-system/sw/share/fonts"
      export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
      export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'

      # DYNAMIC ENVIRONMENT VARIABLES ROUTING MATRIX
      if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
          # FIX: Smoothly hands graphical workspace edits over to your true Zed framework []
          export VISUAL="zed"
          export EDITOR="hx"
      else
          # Fallback to console-native Helix if working over remote headless text terminals
          export VISUAL="hx"
          export EDITOR="hx"
      fi

      # 1. Custom Yazi traversal function (Escaped for Nix)
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

      # 2. Workspace Project Aware Helix launch (Escaped for Nix)
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

      # FIX: Removed the legacy 'ghx()' block entirely to keep paths pristine

      # 4. Fastfetch environment detection logo engine
      fastfetch_dynamic() {
          if [ -f /etc/fedora-release ]; then
              export FF_OS_ICON=""
              export FF_OS_COLOR="blue"
              export FF_LOGO="$HOME/.config/fastfetch/logos/Fedora.png"
          elif ${pkgs.gnugrep}/bin/grep -q "NixOS" /etc/os-release 2>/dev/null; then
              export FF_LOGO="${./assets/NixOS.png}"
          else
              export FF_OS_ICON=""
              export FF_OS_COLOR="green"
              export FF_LOGO=""
          fi
          command fastfetch --logo "$FF_LOGO" --logo-type kitty --logo-width 28 --logo-height 12  "$@"
      }

      if [[ -o interactive ]]; then
          alias fastfetch="fastfetch_dynamic"
          fastfetch_dynamic
      fi
      # Silence the new user configuration prompt for empty home directories
      [[ -f ~/.zshrc || -f ~/.zprofile ]] || export ZDOTDIR="/etc"
    '';
  };
}
