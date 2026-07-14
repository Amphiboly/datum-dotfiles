# ~/Projects/datum-config/home.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Dynamically reads your exported configuration directly into the compilation engine
  productionNoctaliaSettings = lib.importTOML ./noctalia-production.toml;

  tomlFormat = pkgs.formats.toml {};
  noctaliaConfigFile = tomlFormat.generate "noctalia.toml" productionNoctaliaSettings;
in {
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # Main terminal
    ghostty

    # Daily Productivity Suites
    libreoffice-fresh
    thunderbird
    zotero
    zettlr

    # Cloud storage and security
    _1password-cli
    _1password-gui
    dropbox-cli
  ];

  # IDIOMATIC GHOSTTY THEME CONFIGURATION
  xdg.configFile."ghostty/config".text = ''
    theme = light:"Ayu Light",dark:"Night Owl"
    font-size = 8
    shell-integration = zsh
    shell-integration-features = sudo
  '';

  # NOCTALIA Setup
  # A mutable text file asset rather than a read-only store path symlink
  home.file.".config/noctalia/noctalia.toml" = {
    source = noctaliaConfigFile;
    force = true;
  };

  # IDIOMATIC WALLPAPER ASSET DEPLOYMENT
  home.file = {
    "Pictures/wallpapers/rose_pine.png".source = ./assets/rose_pine.png;
    "Pictures/wallpapers/flexoki.png".source = ./assets/flexoki.png;
  };

  # IDIOMATIC NIRI WINDOW MANAGER CONFIGURATION (Owned perfectly by user rik)
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
  # FIREFOX SETUP
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
  # DECLARATIVE FUZZEL LAUNCHER INTEGRATION
  # =========================================================================
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "ghostty";
        font = "JetBrainsMono Nerd Font:size=10";
        prompt = "❯   ";
        width = 40;
        lines = 10;
        tabs = 4;
      };
      colors = {
        # Sleek, minimal dark-blend aesthetic to match your terminal layers
        background = "1a1b26ef";
        text = "a9b1d6ff";
        match = "f7768eff";
        selection = "33467cff";
        selection-text = "c0caf5ff";
        border = "7aa2f7ff";
      };
      border = {
        width = 2;
        radius = 6;
      };
    };
  };

  # DECLARATIVE VIM & GVIM CUSTOMIZATION LAYER
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
  # DECLARATIVE MANGOWC CORE USER CONFIGURATION FILE
  # =========================================================================
  # Natively writes your precise app mappings directly into ~/.config/mango/config.conf
  xdg.configFile."mango/config.conf".text = ''
     exec-once=noctalia
     execOnce="sh -c 'sleep 2 && firefox'"
     execOnce="sh -c 'sleep 4 && ghostty'"

     # ---------------------------------------------------------
     # Core Global Layout Parameters
     # ---------------------------------------------------------
     scroller_structs=100
     scroller_default_proportion=0.55

    # Overview Setting
    hotarea_size=10
    enable_hotarea=0
    ov_tab_mode=1
    ov_no_resize=1
    overviewgappi=5
    overviewgappo=30

    # --- VIEW ACTIONS (Switching Views) ---
    # Press Super + [1-9] to switch directly to that specific tag view
    bind = Super, 1, view, 1
    bind = Super, 2, view, 2
    bind = Super, 3, view, 3
    bind = Super, 4, view, 4
    bind = Super, 5, view, 5
    bind = Super, 6, view, 6
    bind = Super, 7, view, 7
    bind = Super, 8, view, 8
    bind = Super, 9, view, 9

    # --- COMBO VIEWS (Toggle Multiple Tags Simultaneously) ---
    # Press Super + Ctrl + [1-9] to pull additional tags into your current view
    bind = Super+Ctrl, 1, toggleview, 1
    bind = Super+Ctrl, 2, toggleview, 2
    bind = Super+Ctrl, 3, toggleview, 3
    bind = Super+Ctrl, 4, toggleview, 4
    bind = Super+Ctrl, 5, toggleview, 5
    bind = Super+Ctrl, 6, toggleview, 6
    bind = Super+Ctrl, 7, toggleview, 7
    bind = Super+Ctrl, 8, toggleview, 8
    bind = Super+Ctrl, 9, toggleview, 9

    # --- TAG MANAGEMENT (Moving Windows to Tags) ---
    # Press Super + Shift + [1-9] to tag the active window
    bind = Super+Shift, 1, tag, 1
    bind = Super+Shift, 2, tag, 2
    bind = Super+Shift, 3, tag, 3
    bind = Super+Shift, 4, tag, 4
    bind = Super+Shift, 5, tag, 5
    bind = Super+Shift, 6, tag, 6
    bind = Super+Shift, 7, tag, 7
    bind = Super+Shift, 8, tag, 8
    bind = Super+Shift, 9, tag, 9

    # --- TOGGLE WINDOW MULTI-TAGS ---
    # Press Super + Alt + [1-9] to assign a window to an extra tag
    bind = Super+Alt, 1, toggletag, 1
    bind = Super+Alt, 2, toggletag, 2
    bind = Super+Alt, 3, toggletag, 3
    bind = Super+Alt, 4, toggletag, 4
    bind = Super+Alt, 5, toggletag, 5
    bind = Super+Alt, 6, toggletag, 6
    bind = Super+Alt, 7, toggletag, 7
    bind = Super+Alt, 8, toggletag, 8
    bind = Super+Alt, 9, toggletag, 9

    # --- VIEW ALL TAGS ---
    # Press Super + 0 to look at all windows across all tags
    bind = Super, 0, view, all

     # ---------------------------------------------------------
     # GLOBAL COMMON ENVIRONMENT ACTIONS
     #   Binds declared under 'common' evaluate identically across all modes
     # ---------------------------------------------------------
     keymode=common
     bind=SUPER,R,reload_config

     # ---------------------------------------------------------
     # DEFAULT COMPOSITOR OPERATIONAL MODE BINDINGS
     # ---------------------------------------------------------
     keymode=default

     # Core Application Launchers (Lowercase key triggers for single-tap usage)
     bind=SUPER,Return,spawn,ghostty
     bind=SUPER,t,spawn,ghostty
     bind=SUPER,p,spawn,fuzzel
     bind=SUPER,b,spawn,firefox
     bind=SUPER,z,spawn,zed

     # Help and overview
     bind=ALT,Tab,toggleoverview,
     bind=SUPER,o,toggleoverlay,

     # Layout Tiling Mode Toggles
     bind=SUPER,space,setlayout,scroller
     bind=SUPER,m,setlayout,monocle
     bind=SUPER,f,setlayout,center_tile
     bind=SUPER+SHIFT,space,switch_layout
     bind=SUPER,v,togglefloating
     bind=SUPER+SHIFT,v,togglefullscreen

     # Core Window & Session Management Commands
     bind=SUPER,q,killclient,
     bind=SUPER+SHIFT,e,quit,

     # Mode Shifts jumping into your resize submap block
     bind=SUPER,F,setkeymode,resize

     # ---------------------------------------------------------
     # ACTIVE INTERACTIVE RESIZE/MOVE WINDOWS MODE BINDINGS
     # ---------------------------------------------------------
     keymode=resize
     # Arrow manipulation maps processing window scaling directions
     bind=NONE,Left,resizewin,-10,+0
     bind=NONE,Right,resizewin,+10,+0
     bind=NONE,Up,resizewin,+0,-10
     bind=NONE,Down,resizewin,+0,+10
     # Shift arrow moves windows
     bind=NONE+SHIFT,Left,movewin,-50,+0
     bind=NONE+SHIFT,Right,movewin,+50,+0
     bind=NONE+SHIFT,Up,movewin,+0,-50
     bind=NONE+SHIFT,Down,movewin,+0,+50
     # Safety breakout return loop resetting keymaps back to default space
     bind=NONE,Escape,setkeymode,default
     bind=NONE,Return,setkeymode,default

     # ---------------------------------------------------------
     # Experimental
     # ---------------------------------------------------------
     # Window effect
     blur=0
     blur_layer=0
     blur_optimized=1
     blur_params_num_passes = 2
     blur_params_radius = 5
     blur_params_noise = 0.02
     blur_params_brightness = 0.9
     blur_params_contrast = 0.9
     blur_params_saturation = 1.2

     shadows = 0
     layer_shadows = 0
     shadow_only_floating = 1
     shadows_size = 10
     shadows_blur = 15
     shadows_position_x = 0
     shadows_position_y = 0
     shadowscolor= 0x000000ff

     border_radius=6
     no_radius_when_single=0
     focused_opacity=1.0
     unfocused_opacity=1.0

     # Animation Configuration(support type:zoom,slide)
     # tag_animation_direction: 1-horizontal,0-vertical
     animations=1
     layer_animations=1
     animation_type_open=slide
     animation_type_close=slide
     animation_fade_in=1
     animation_fade_out=1
     tag_animation_direction=1
     zoom_initial_ratio=0.4
     zoom_end_ratio=0.8
     fadein_begin_opacity=0.5
     fadeout_begin_opacity=0.8
     animation_duration_move=500
     animation_duration_open=400
     animation_duration_tag=350
     animation_duration_close=800
     animation_duration_focus=0
     animation_curve_open=0.46,1.0,0.29,1
     animation_curve_move=0.46,1.0,0.29,1
     animation_curve_tag=0.46,1.0,0.29,1
     animation_curve_close=0.08,0.92,0,1
     animation_curve_focus=0.46,1.0,0.29,1
     animation_curve_opafadeout=0.5,0.5,0.5,0.5
     animation_curve_opafadein=0.46,1.0,0.29,1

     # --- Noctalia v5 Core Core Interface Keys ---
     bind=SUPER, space, spawn, noctalia msg panel-toggle launcher
     bind=SUPER, s,     spawn, noctalia msg panel-toggle control-center
     bind=SUPER, comma, spawn, noctalia msg settings-toggle

     # --- Hardware Media Key Mapping ---
     bind=NONE, XF86AudioRaiseVolume,   spawn, noctalia msg volume-up
     bind=NONE, XF86AudioLowerVolume,   spawn, noctalia msg volume-down
     bind=NONE, XF86AudioMute,          spawn, noctalia msg volume-mute
     bind=NONE, XF86MonBrightnessUp,    spawn, noctalia msg brightness-up
     bind=NONE, XF86MonBrightnessDown,  spawn, noctalia msg brightness-down

  '';

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
  # GRAPHICAL ENVIRONMENT GLOBAL DEFAULT EDITOR ASSOCIATIONS
  # =========================================================================
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = ["zed.desktop"];
      "text/markdown" = ["zed.desktop"];
      "application/x-shellscript" = ["zed.desktop"];
    };
  };
}
