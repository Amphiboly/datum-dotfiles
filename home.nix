# ~/Projects/datum-config/home.nix
{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: {
  home.stateVersion = "26.05";

  # =========================================================================
  # 1. Applications
  # =========================================================================
  home.packages = with pkgs; [
    # Custom Script Compilations
    (writeScriptBin "mksecrets" (builtins.readFile ./mksecrets.sh))

    # Main terminal and editors
    kitty
    helix
    zellij
    zed-editor
    nixd
    tinymist
    #    vim-full  # vim is declared below

    # Shell tools
    bat
    eza
    fastfetch
    ripgrep
    dust

    # Shell integrations
    antidote
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search

    # Nix utilities
    comma
    nvd
    nil
    alejandra

    # Foundational Unix Utility Layer left out by NixOS:
    btop
    e2fsprogs
    file
    tree
    unzip
    wget
    which

    # Just for fun (or the animal names)
    cmatrix
    cowsay
    tealdeer

    # Daily Productivity Suites
    glow
    libreoffice-fresh
    mdbook
    naps2
    pandoc
    (texlive.withPackages (ps:
      with ps; [
        scheme-infraonly
        context
        collection-luatex
      ]))
    thunderbird
    zettlr
    zotero

    # Cloud storage and security
    _1password-cli
    _1password-gui
    maestral

    # Permanent user binary link so 'spawn,zed' works natively
    (runCommand "zed-cli-link" {} "mkdir -p $out/bin && ln -s ${zed-editor}/bin/zeditor $out/bin/zed")
  ];

  # =========================================================================
  # 2. Shell context and environmental mappings
  # =========================================================================
  home.sessionVariables = {
    EDITOR = "helix";
    VISUAL = "zed";
    TERMINAL = "kitty";
    _ZO_DATA_DIR = "$HOME/.local/share/zoxide";
    _FZF_PREVIEW_CMD = "bat --color=always --style=plain,numbers --line-range=:500 {}";
  };

  # =========================================================================
  # 3. Graphical associations
  # =========================================================================
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = ["dev.zed.Zed.desktop"];
      "text/markdown" = ["dev.zed.Zed.desktop"];
      "application/x-shellscript" = ["dev.zed.Zed.desktop"];
    };
  };
  xdg.terminal-exec = {
    enable = true;
    settings.default = ["kitty.desktop"]; # Swift transition to Kitty
  };

  # =======================================================================
  # 4. Declarative Starship Customizations
  # =======================================================================
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = "$git_branch $git_status $directory $character";
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold cyan";
      };
      git_branch = {
        symbol = "🌱 ";
        style = "bold magenta";
        format = "on [$symbol$branch]($style) ";
      };
      git_status = {
        style = "bold red";
        conflicted = "🏳 ";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕";
        untracked = " +?";
        modified = " *~";
        staged = " +";
        renamed = " »";
        deleted = " -";
        format = "([$all_status$ahead_behind]($style) )";
      };
      character = {
        success_symbol = "[ I ](bold green) ❯";
        error_symbol = "[ I ](bold red) ❯";
        vimcmd_symbol = "[ N ](bold yellow) ❯";
        vimcmd_replace_one_symbol = "[ R ](bold purple) ❯";
        vimcmd_replace_symbol = "[ R ](bold purple) ❯";
        vimcmd_visual_symbol = "[ V ](bold magenta) ❯";
      };
    };
  };

  # =======================================================================
  # 5. Maestral Dropbox Tracking Pipeline
  # =======================================================================
  systemd.user.services.maestral = {
    Unit = {Description = "Maestral Dropbox Synchronization Daemon";};
    Install = {WantedBy = ["graphical-session.target"];};
    Service = {
      ExecStart = "${pkgs.maestral}/bin/maestral start -f";
      ExecStop = "${pkgs.maestral}/bin/maestral stop";
      Restart = "on-failure";
      Nice = 10;
    };
  };

  # =======================================================================
  # 6. Zsh Shell Configurations
  # =======================================================================
  programs.zsh = {
    enable = true;
    enableCompletion = true;
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

      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

      bindkey -v
      export KEYTIMEOUT=1
      bindkey '^?' backward-delete-char
      bindkey '^H' backward-delete-char
      bindkey '^w' backward-kill-word
      bindkey '^r' history-incremental-search-backward
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

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
             export FF_LOGO="${./assets/NixOS.png}"
          else
              export FF_OS_ICON=""
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

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # =========================================================================
  # The following is disabled after the initial build so that home-manager
  # does not rebuild the accounts, losing non-smtp accounts in the process.
  # NOTE: The password entries are untested.
  # 1. CLEAN THUNDERBIRD MAIN SYSTEM BLOCK FOR REFERENCE
  # =========================================================================
  # programs.thunderbird = {
  #   enable = true;
  #   profiles.default = {
  #     isDefault = true;
  #     feedAccounts = {};
  #     settings = {
  #       "mail.accountmanager.rememberpasswords" = true;
  #       "mail.root.none" = true;
  #     };
  #   };
  # };
  #
  # -------------------------------------------------------------------------
  # THE THUNDERBIRD EMAIL ACCOUNTS FOR REFERENCE
  # -------------------------------------------------------------------------
  # accounts.email.accounts = {
  #   "Panix Mail" = {
  #     primary = true;
  #     realName = "Rik Kabel";
  #     address = "rik@panix.com";
  #     userName = "rik@panix.com";
  #     flavor = "plain";
  #     imap = {
  #       host = "mail.panix.com";
  #       port = 143;
  #       tls = {
  #         enable = true;
  #         useStartTls = true;
  #       };
  #     };
  #     smtp = {
  #       host = "mail.panix.com";
  #       port = 587;
  #       tls = {
  #         enable = true;
  #         useStartTls = true;
  #       };
  #     };
  #     thunderbird = {
  #       enable = true;
  #       profiles = ["default"];
  #     };
  #     passwordFile = config.sops.secrets."panix-smtp-password".path;
  #   };

  #   "Spectrum Mail" = {
  #     realName = "Richard Kabel";
  #     address = "kabel5cd@charter.net";
  #     userName = "kabel5cd@charter.net";
  #     flavor = "plain";
  #     imap = {
  #       host = "mobile.charter.net";
  #       port = 993;
  #       tls = {
  #         enable = true;
  #         useStartTls = false;
  #       };
  #     };
  #     smtp = {
  #       host = "mobile.charter.net";
  #       port = 587;
  #       tls = {
  #         enable = true;
  #         useStartTls = true;
  #       };
  #     };
  #     thunderbird = {
  #       enable = true;
  #       profiles = ["default"];
  #     };
  #     passwordFile = config.sops.secrets."spectrum-smtp-password".path;
  #   };

  #   "Amphiboly Gmail" = {
  #     realName = "Rik Kabel";
  #     address = "amphiboly@gmail.com";
  #     userName = "amphiboly@gmail.com";
  #     flavor = "gmail.com";
  #     thunderbird = {
  #       enable = true;
  #       profiles = ["default"];
  #       settings = id: {
  #         "mail.server.server_${id}.authMethod" = 10;
  #         "mail.smtpserver.smtp_${id}.authMethod" = 10;
  #       };
  #     };
  #     passwordFile = config.sops.secrets."gmail-amphiboly-password".path;
  #   };

  #   "Amphiboly Backup Gmail" = {
  #     realName = "Rik Kabel";
  #     address = "amphiboly.backup@gmail.com";
  #     userName = "amphiboly.backup@gmail.com";
  #     flavor = "gmail.com";
  #     thunderbird = {
  #       enable = true;
  #       profiles = ["default"];
  #       settings = id: {
  #         "mail.server.server_${id}.authMethod" = 10;
  #         "mail.smtpserver.smtp_${id}.authMethod" = 10;
  #       };
  #     };
  #     passwordFile = config.sops.secrets."gmail-amphibolybackup-password".path;
  #   };

  #   "Cornwall HOA Gmail" = {
  #     realName = "Cornwall Association";
  #     address = "Cornwall.HOA@gmail.com";
  #     userName = "Cornwall.HOA@gmail.com";
  #     flavor = "gmail.com";
  #     thunderbird = {
  #       enable = true;
  #       profiles = ["default"];
  #       settings = id: {
  #         "mail.server.server_${id}.authMethod" = 10;
  #         "mail.smtpserver.smtp_${id}.authMethod" = 10;
  #       };
  #     };
  #     passwordFile = config.sops.secrets."gmail-cornwall-password".path;
  #   };
  # };

  # =========================================================================
  # 2. THE NEWSBOAT RSS FEED MODULE
  # =========================================================================
  programs.newsboat = {
    enable = true;
    autoReload = true;
    reloadTime = 30;
    extraConfig = ''
      show-keymap-hint yes
      browser "${pkgs.w3m}/bin/w3m"
    '';
  };

  # Generate a cleanly formatted plain-text urls file from your XML asset
  home.file.".config/newsboat/urls".text = let
    rawXml = builtins.readFile ./assets/feeds.opml;
    # Extract strings matched inside standard xml xmlUrl="..." properties
    lines = builtins.filter (builtins.isString) (builtins.split "xmlUrl=\"([^\"]+)\"" rawXml);
    # Extract structural tags if present, or fallback to an empty string line mapping
    cleanUrls = builtins.concatStringsSep "\n" (builtins.map (match: builtins.head match) (builtins.filter builtins.isList (builtins.split "xmlUrl=\"([^\"]+)\"" rawXml)));
  in
    if cleanUrls != ""
    then cleanUrls
    else ''
      # Fallback defaults if parsing fails
      http://sesquiotic.wordpress.com/feed/
    '';

  # =========================================================================
  # DECLARATIVE COSMIC DE KEYBOARD INTERCEPT OVERRIDES
  # =========================================================================
  # This targets COSMIC's native configuration engine, forcing the Wayland
  # compositor to instantly bind Right Alt as the Compose multi-key on boot.
  home.file.".config/cosmic/com.system76.CosmicInput/v1/keys".text = ''
    (
        caps_lock: None,
        num_lock: true,
        scroll_lock: false,
        xkb_options: Some("compose:ralt"),
    )
  '';

  # =========================================================================
  # DECLARATIVE VIM DIGRAPH REPOSITORY INTEGRATION
  # =========================================================================
  # Directly map the complete file, locally stored
  home.file.".XCompose".source = ./assets/xcompose-vim;

  # =========================================================================
  # KITTY TERMINAL INTEGRATION (home.nix)
  # =========================================================================
  programs.kitty = {
    enable = true;
    autoThemeFiles = {
      light = "ayu_light";
      dark = "Catppuccin-Mocha";
      noPreference = "Catppuccin-Mocha";
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      scrollback_lines = 10000;
      close_on_child_death = "yes";
      update_check_interval = 0; # Disables redundant background update checks
      background_opacity = "0.95";

      "wayland_enable_ime" = "no";

      # —————————————————————————————————————————————————————————————————————
      # ZELLIJ KEYBIND PASS-THROUGH OVERRIDES
      # —————————————————————————————————————————————————————————————————————
      "map ctrl+shift+t" = "no_op";
      "map ctrl+shift+w" = "no_op";
      "map ctrl+shift+enter" = "no_op";
    };
  };

  # =========================================================================
  # NATIVE INFRASTRUCTURE DEPLOYMENT: REMMINA WITH COUPLING PLUGINS
  # =========================================================================
  services.remmina = {
    enable = true;
    addRdpMimeTypeAssoc = true;
  };

  # ========================================================================
  # IDIOMATIC WALLPAPER ASSET DEPLOYMENT
  # =========================================================================
  home.file = {
    "Pictures/wallpapers/rose_pine.png".source = ./assets/rose_pine.png;
    "Pictures/wallpapers/flexoki.png".source = ./assets/flexoki.png;
  };

  # =========================================================================
  # FIREFOX SETUP
  # =========================================================================
  programs.firefox = {
    enable = true;
    profiles.default = {
      id = 0;
      name = "Default";
      isDefault = true;

      settings = {
        "browser.aboutwelcome.enabled" = false;
        "browser.startup.homepage" = "https://nixos.org";
        "browser.search.defaultenginename" = "DuckDuckGo";
        "signon.rememberSignons" = false;
        "privacy.resistFingerprinting" = true;
        "extensions.autoDisableScope" = 0;
      };

      bookmarks = {
        force = true;
        settings = import ./bookmarks.nix;
      };

      # Nested extensions block with local scoped variables
      extensions = {
        force = true;
        packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ghostery
          sidebery
          onepassword-password-manager
        ];
      };
    };
  };

  # =========================================================================
  # DECLARATIVE HELIX INTEGRATION (home.nix)
  # =========================================================================
  programs.helix = {
    enable = true;

    # 1. CORE EDITOR & KEYBOARD LAYOUT TRACKS (Generates config.toml)
    settings = {
      theme = "onelight";

      editor = {
        line-number = "relative";
        cursorline = true;
        bufferline = "multiple";

        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };

        search = {
          smart-case = false;
        };

        indent-guides = {
          render = true;
          character = "┋";
          skip-levels = 1;
        };

        whitespace.characters = {
          space = " ";
          tab = "→";
          newline = "⏎";
        };

        file-picker = {
          hidden = false;
        };

        statusline = {
          separator = "│";
          left = ["mode" "spacer" "spinner" "version-control" "spacer" "file-name" "file-modification-indicator"];
          center = [];
          right = ["diagnostics" "workspace-diagnostics" "selections" "position" "position-percentage" "file-type"];

          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "VISUAL";
          };
        };

        lsp = {
          display-inlay-hints = true;
        };
      };

      keys.normal = {
        "tab" = ":buffer-next";
        "S-tab" = ":buffer-previous";
        "C-p" = ":lsp-workspace-command tinymist.pinMain \"%sh{realpath %{buffer_name}}\"";
        "C-w" = ":buffer-close";
        "backspace" = "goto_next_diag";
        "X" = ["select_mode" "extend_line"];

        # Interactive TTY yazi picker link
        C-y = ":sh yazi \"%{buffer_name}\" --chooser-file=/tmp/yazi-helix-picker; if [ -f /tmp/yazi-helix-picker ]; then hx_open=$(cat /tmp/yazi-helix-picker); rm -f /tmp/yazi-helix-picker; helix -c \":open '$hx_open'\"; fi";

        space = {
          T = ":sh typst compile \"%{buffer_name}\"";
          x = ":toggle whitespace.render all none";

          # Space + n opens the menu, then tap 'd' (day) or 'n' (night)
          n = {
            d = ":theme onelight";
            n = ":theme catppuccin_mocha";
          };
        };
      };
    };
    # 2. LANGUAGES STANZA: Placed parallel to settings, compiling natively into languages.toml
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          language-servers = ["nixd"];
          formatter = {command = "${pkgs.alejandra}/bin/alejandra";};
        }
        {
          name = "typst";
          auto-format = true;
          language-servers = ["tinymist"];
        }
        {
          name = "markdown";
          auto-format = true;
          language-servers = ["marksman"];
          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = ["--parser" "markdown"];
          };
        }
      ];

      language-server = {
        # Advanced Nixd Engine with Deep Flake Evaluation Integration
        nixd = {
          command = "${pkgs.nixd}/bin/nixd";
          args = ["--semantic-tokens=true"];

          # Use Nix multiline string symbols (''...) to protect the internal quotes
          config.nixd = {
            nixpkgs.expr = ''import (builtins.getFlake "$root").inputs.nixpkgs { }'';
            options = {
              nixos.expr = ''(builtins.getFlake "$root").nixosConfigurations."datum-laptop".options'';
            };
          };
        };

        tinymist = {
          command = "${pkgs.tinymist}/bin/tinymist";
        };
        marksman = {
          command = "${pkgs.marksman}/bin/marksman";
        };
      };
    };
  };

  # =========================================================================
  # DECLARATIVE VIM & GVIM CUSTOMIZATION LAYER
  # =========================================================================
  programs.vim = {
    enable = true;

    # Ensures Home Manager targets the full graphical build package we set up system-wide
    packageConfigurable = pkgs.vim-full;

    # 1. Declarative Plugin Allocations (Completely replaces mutable manual vim_plug setups)
    plugins = with pkgs.vimPlugins; [
      nerdtree
      vim-airline
      vim-airline-themes
    ];

    # 2. Native .vimrc Keymaps and Window Behaviours Settings
    extraConfig = ''
      " Standard graphical GVim font overrides for your newly added Cascadia Code font
      if has("gui_running")
        set guifont=Cascadia\ Code\ NF:h10
        set guioptions-=m " Hide standard top application menus to keep desktop workspace clean
        set guioptions-=t " Remove toolbar overlays to match your minimalist aesthetic
      endif

      " Core Interface Options
      set number
      set relativenumber
      set mouse=a
      set clipboard=unnamedplus

      " Automated plugin commands mapping
      let g:airline_powerline_fonts = 1
      let g:airline_theme = 'dark'

      " Quick hotkey to toggle NERDTree instantly via terminal or GUI windows
      nnoremap <C-n> :NERDTreeToggle<CR>
    '';
  };

  # =========================================================================
  # HIGH-PERFORMANCE ZED INTEGRATION MATRIX
  # =========================================================================
  programs.zed-editor = {
    enable = true;

    # 1. Declarative Extension Pre-install Array Set
    extensions = [
      "nix" # Official Nix expression syntax highlighter and formatter tracking
      "typst" # Native Tinymist language compiler environment link
    ];

    # 2. Strict JSON Environment Workspace Settings Handling
    userSettings = {
      # Visual Typography Configurations using your verified Cascadia font block
      theme = "Night Owl";
      ui_font_size = 15;
      buffer_font_family = "Cascadia Code NF";
      buffer_font_size = 14;

      # Smooth modern desktop UI interface behaviors
      telemetry = {
        metrics = false;
        crash_reporting = false;
      };

      # Language Specific Workspace Formatter Pipelines
      languages = {
        Nix = {
          language_servers = ["nixd"];
          format_on_save = "on";
        };
        Typst = {
          language_servers = ["tinymist"];
          format_on_save = "on";
        };
      };
    };
  };

  # =========================================================================
  #  TERMINAL NAVIGATION & SHELL HOOKS
  # =========================================================================
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # =========================================================================
  # DESKTOP ENTRY COMPOSITOR ALIGNMENT
  # =========================================================================
  xdg.desktopEntries.yazi = {
    name = "Yazi";
    exec = "kitty -- yazi %u";
    terminal = false;
    icon = "yazi";
    categories = ["System" "FileTransfer"];
  };
}
