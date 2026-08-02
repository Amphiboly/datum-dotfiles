# ~/Projects/datum-config/home.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # Main terminal
    ghostty

    # Nix utilities
    nvd
    nil
    alejandra
    
    # Foundational Unix Utility Layer left out by NixOS:
    e2fsprogs
    file
    tree
    unzip
    wget
    which

    # Just for fun (or the animal names)
    cowsay
    tealdeer
    
    # Daily Productivity Suites
    glow
    libreoffice-fresh
    zettlr
    zotero

    # Cloud storage and security
    _1password-cli
    _1password-gui
  ];
 
  # =========================================================================
  # 1. CLEAN THUNDERBIRD MAIN SYSTEM BLOCK
  # =========================================================================
  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
    };
  };
          
  # =========================================================================
  # 2. THE EMAIL ACCOUNTS MODULE
  # =========================================================================
  accounts.email.accounts = {
    "panix-mail" = {
      primary = true;
      realName = "Rik Kabel";
      address = "rik@panix.com";
      userName = "rik@panix.com";
      flavor = "plain";
      imap = { host = "mail.panix.com"; port = 993; tls.enable = true; };
      smtp = { host = "mail.panix.com"; port = 587; tls = { enable = true; useStartTls = true; }; };
      thunderbird = { enable = true; profiles = [ "default" ]; };
    };

    "spectrum-mail" = {
      realName = "Richard Kabel";
      address = "kabel5cd@charter.net";
      userName = "kabel5cd@charter.net";
      flavor = "plain";
      imap = { host = "mobile.charter.net"; port = 993; tls = { enable = true; useStartTls = false; }; };  
      smtp = { host = "mobile.charter.net"; port = 587; tls = { enable = true; useStartTls = true; }; };
      thunderbird = {
         enable = true;
         profiles = [ "default" ];
         settings = id: {
           "mail.server.server_${id}.socketType" = 3;
           "mail.smtpserver.smtp_${id}.socketType" = 2;
         };
      };
    };

    "gmail-personal" = {
      realName = "Rik Kabel";
      address = "amphiboly@gmail.com";
      userName = "amphiboly@gmail.com";
      flavor = "gmail.com";
      thunderbird = {
        enable = true; profiles = [ "default" ];
        settings = id: { "mail.server.server_${id}.authMethod" = 10; "mail.smtpserver.smtp_${id}.authMethod" = 10; }; #
      };
    };

    "gmail-backup" = {
      realName = "Rik Kabel";
      address = "amphiboly.backup@gmail.com";
      userName = "amphiboly.backup@gmail.com";
      flavor = "gmail.com";
      thunderbird = {
        enable = true; profiles = [ "default" ];
        settings = id: { "mail.server.server_${id}.authMethod" = 10; "mail.smtpserver.smtp_${id}.authMethod" = 10; }; #
      };
    };

    "gmail-HOA" = {
      realName = "Cornwall Association";
      address = "Cornwall.HOA@gmail.com";
      userName = "Cornwall.HOA@gmail.com";
      flavor = "gmail.com";
      thunderbird = {
        enable = true; profiles = [ "default" ];
        settings = id: { "mail.server.server_${id}.authMethod" = 10; "mail.smtpserver.smtp_${id}.authMethod" = 10; }; #
      };
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
  # IDIOMATIC NIRI WINDOW MANAGER CONFIGURATION (Owned perfectly by user rik)
  # =========================================================================
  home.pointerCursor = {
    enable = true;
    gtk.enable=true;
    x11.enable=true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };
  xdg.configFile."niri/config.kdl".text = ''
       input {
           keyboard {
               xkb {
                   layout "us"
               }
               repeat-delay 250
               repeat-rate 35
           }
           touchpad {
               tap
               natural-scroll
           }
       }
       layout {
           gaps 10
           default-column-width { proportion 0.5; }
           focus-ring {
               width 4
               active-color "#7aa2f7"
               inactive-color "#414868"
           }
       }
       binds {
           // --- Core Responsive Terminal Trigger ---
           Mod+T { spawn "ghostty"; }
           // --- Web Browser Bind ---
           Mod+B { spawn "firefox"; }
           // --- Window & Layout Actions ---
           Mod+Shift+Q { close-window; }
           Mod+Left    { focus-column-left; }
           Mod+Right   { focus-column-right; }
           Mod+Up      { focus-window-or-workspace-up; }
           Mod+Down    { focus-window-or-workspace-down; }
           // --- View Manipulation ---
           Mod+O       { toggle-overview; }
           // --- System Controls ---
           Mod+Shift+Slash { show-hotkey-overlay; }
           Mod+Shift+E     { quit; }
   //      Mod+Shift+R     { spawn "niri" "msg" "action" "reload-config"; }
           Mod+Shift+R     { spawn "sh" "-c" "niri msg action load-config-file && niri msg action reload-config-noctalia || pkill -USR1 noctalia"; }
           // --- Column & Workspace Positioning Layout Controls ---
           Mod+Shift+Left  { move-column-left; }
           Mod+Shift+Right { move-column-right; }
           Mod+R           { switch-preset-column-width; }
           Mod+F           { maximize-column; }
           Mod+Shift+F     { fullscreen-window; }
           Mod+V           { toggle-window-floating; }
           Mod+Shift+V     { switch-focus-between-floating-and-tiling; }
           // --- Launcher & Hardware Mechanics ---
           Mod+D       { spawn "sh" "-c" "noctalia || launcher"; }
           Mod+P       { spawn "fuzzel"; }
       }
       output "eDP-1" {
         background-color "#1a1b26"
       }
       spawn-at-startup "sh" "-c" "sleep 1 && noctalia"
  '';

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
        force = true; # Overrides browser database constraints to push Nix bookmarks
        settings = import ./bookmarks.nix;
      };

      # See github nix-community/nur-combined for available packages
      extensions = {
        force = true; # Permits Home Manager to write extension states to the disk
        packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ghostery
          sidebery
          onepassword-password-manager
        ];
      };
    };
  };

  # =========================================================================
  # DECLARATIVE GHOSTTY INTEGRATION
  # =========================================================================
  programs.ghostty.enable = false; # it generates config, not config.ghostty
  xdg.configFile."ghostty/config.ghostty".text = ''
    font-family = JetBrainsMono Nerd Font
    font-size = 10
    theme = light:"Ayu Light",dark:"Night Owl"
    window-decoration = none
    command = "${pkgs.zsh}/bin/zsh"
    clipboard-read = allow
    clipboard-write = allow
    copy-on-select = clipboard
    shell-integration = zsh
    shell-integration-features = sudo
  '';

  # =========================================================================
  # IDIOMATIC GHOSTTY THEME CONFIGURATION
  # =========================================================================
  xdg.configFile."ghostty/config"= {
    text = ''
      font-size = 8
      shell-integration = zsh
      shell-integration-features = sudo
    '';
    force = true;
  };

  # =========================================================================
  # DECLARATIVE HELIX INTEGRATION
  # =========================================================================
  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_mocha";
      editor = {
        clipboard-provider = "termcode";
        line-number = "relative";
        file-picker.max-depth = 5;
        statusline = {
          left = [ "mode" "spinner" "version-control" "file-name" "file-modification-indicator" ];
          center = [ ];
          right = [ "diagnostics" "selections" "register" "file-type" "position" "position-percentage" ];
          separator = "│";
        };
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          language-servers = [ "nil" ];
        }
      ];
      language-server.nil = {
        command = "nil";
        config.nil.formatting.command = [ "nixpkgs-fmt" ];
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
    exec = "ghostty -e yazi %u";
    terminal = false;
    icon = "yazi";
    categories = [ "System" "FileTransfer" ];
  };
 }
