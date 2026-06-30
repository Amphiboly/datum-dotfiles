# Created by newuser for 5.9
#   modified by rik and ai

# Enable next for profiling
# zmodload zsh/zprof
# Enable previous for profiling

# ---------------------------------------------------------
#   Environment & Paths (Shared)
# ---------------------------------------------------------
typeset -U path
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
if ! [[ "$PATH" =~ "$HOME/context/tex/texmf-linux-64/bin" ]]; then
    PATH="$HOME/context/tex/texmf-linux-64/bin:$PATH"
fi
if ! [[ "$PATH" =~ "$HOME/.cargo/bin" ]]; then
    PATH="$PATH:$HOME/.cargo/bin"
fi
PATH="$HOME/.nix-profile/bin:$PATH"
export PATH

export OSFONTDIR=/usr/share/fonts

export HISTSIZE=50000
export HISTFILE="$ZDOTDIR/.zsh_history"
export SAVEHIST=50000

export KEYTIMEOUT=1

export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'
export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"
export NVM_DIR="$HOME/.nvm"
export _ZO_DATA_DIR=$HOME/.local/share/zoxide

# Define a single, locked cache file destination for Ghostty tabs
export ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump"

# Check if a graphical display environment is available
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    export VISUAL="ghx"   # Uses your new non-blocking Ghostty + Helix window
    export EDITOR="hx"    # Inline terminal editing fallback
else
    export VISUAL="hx"    # Text-only or SSH environment
    export EDITOR="hx"
fi

# Custom text color for the ghost suggestions (Faint Gray)
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=117"
# Optimize execution speed by checking the history cache first
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ---------------------------------------------------------
#   Set vi mode & Completion Styles
# ---------------------------------------------------------
bindkey -v

# ---------------------------------------------------------
#  Aliases & Functions
# ---------------------------------------------------------
alias cat='bat'
alias ls='eza --icons --colour=auto --colour-scale=all --icons=auto'
alias la='eza --icons --colour=auto --colour-scale=all --icons=auto -la'
alias ll='eza --icons --colour=auto --colour-scale=all --icons=auto -ll'
alias lm='eza --icons --colour=auto --colour-scale=all --icons=auto -ll -s modified'
alias tree='eza --icons --tree'
alias ffetch='fastfetch -c all.jsonc'
alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias ollama='OLLAMA_NUM_PARALLEL=1 ollama'

# yazi
y() {
   local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
   command yazi "$@" --cwd-file="$tmp"
   IFS= read -r -d '' cwd < "$tmp"
   [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
   rm -f -- "$tmp"
}
if [[ -o interactive ]]; then
    # fastfetch dynamic logo
    fastfetch_dynamic() {
        if [ -f /etc/fedora-release ]; then
            export FF_OS_ICON=""
            export FF_OS_COLOR="blue"
            export FF_LOGO="$HOME/.config/fastfetch/logos/Fedora.png"
        elif grep -q "NixOS" /etc/os-release 2>/dev/null; then
            export FF_OS_ICON=""
            export FF_OS_COLOR="cyan"
            export FF_LOGO="$HOME/.config/fastfetch/logos/NixOS.png"
        elif grep -q "CachyOS" /etc/os-release 2>/dev/null; then
            export FF_OS_ICON=""
            export FF_OS_COLOR="green"
            export FF_LOGO="$HOME/.config/fastfetch/logos/CachyOS.png"
        else
            export FF_OS_ICON=""
            export FF_OS_COLOR="green"
            export FF_LOGO=""
        fi
        command fastfetch --logo "$FF_LOGO" "$@"
    }
fi


# In-terminal workspace detection for helix
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
# Non-blocking Helix (gvim style)
ghx() {
  local project_root
  project_root=$(git rev-parse --show-toplevel 2>/dev/null || \
                 find . -maxdepth 5 -name "flake.nix" -exec dirname {} \; 2>/dev/null | head -n 1)

  if [[ -n "$1" ]]; then
    ghostty +new-window --working-directory="$PWD" --command="hx $*" &!
  elif [[ -n "$project_root" ]]; then
    ghostty +new-window --working-directory="$project_root" --command="hx ." &!
  else
    ghostty +new-window --working-directory="$PWD" --command="hx" &!
  fi
}

# ---------------------------------------------------------
#   History & Shell Settings
# ---------------------------------------------------------
setopt SHARE_HISTORY          
setopt HIST_REDUCE_BLANKS     
setopt APPEND_HISTORY
setopt HIST_FIND_NO_DUPS      
setopt HIST_EXPIRE_DUPS_FIRST 
setopt HIST_IGNORE_DUPS      
setopt HIST_IGNORE_SPACE     
setopt AUTO_CD                
setopt NUMERIC_GLOB_SORT      

# ---------------------------------------------------------
#   Antidote Plugin Loader (Puts plugin paths into $fpath)
# ---------------------------------------------------------
source "$ZDOTDIR/.antidote/antidote.zsh"
antidote load "$ZDOTDIR/.zsh_plugins.txt"

# ---------------------------------------------------------
#   FZF Configuration & Custom Core Fpaths
# ---------------------------------------------------------
fpath=(
    /usr/share/zsh/functions/Zle
    /usr/share/zsh/current/functions/Zle
    /usr/local/share/zsh/functions
    $fpath
)

bindkey -M viins '^R' fzf-history-widget

_fzf_file_no_hidden() {
  local cmd result
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="$result"  
  zle reset-prompt
}
zle -N _fzf_file_no_hidden

# ---------------------------------------------------------
#   Completion Engine (Runs AFTER Antidote hooks $fpath)
# ---------------------------------------------------------
autoload -Uz compinit
if [[ -n $ZSH_COMPDUMP(#qN.mh+24) ]]; then
  compinit -i -d "$ZSH_COMPDUMP"
else
  compinit -C -i -d "$ZSH_COMPDUMP"
fi

# ---------------------------------------------------------
#    Lazy Load NVM Setup
# ---------------------------------------------------------
load_nvm() {
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm() { unset -f nvm node npm npx; load_nvm; nvm "$@"; }
node() { unset -f nvm node npm npx; load_nvm; node "$@"; }
npm() { unset -f nvm node npm npx; load_nvm; npm "$@"; }
npx() { unset -f nvm node npm npx; load_nvm; npx "$@"; }

# ---------------------------------------------------------
#   Other Key Bindings (Must go AFTER antidote load)
# ---------------------------------------------------------
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward

zle -N history-substring-search-up
zle -N history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ---------------------------------------------------------
#   Interactive tools and prompt
# ---------------------------------------------------------
if [[ -o interactive ]]; then
    # zoxide
    eval "$(zoxide init zsh)"
    
    # fzf
    eval "$(fzf --zsh)"
    
    # starship (Single instance loop check)
    if (( ! ${+functions[starship_zle-keymap-select]} )); then
        eval "$(starship init zsh)"
    fi
    
    # fastfetch dynamic logo
    alias fastfetch="fastfetch_dynamic"
    
    # Run it on startup
    fastfetch_dynamic
fi

# zprof  # remove when done

