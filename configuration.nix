# ~/Projects/datum-config/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  # =========================================================================
  # 1. GLOBAL SECRETS LEDGER NATIVE PERMISSIONS
  # =========================================================================
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops/age/keys.txt";
    secrets = {
      # System & Admin Keys
      "rik-password-hash" = {neededForUsers = true;};
      "w11-cifs-password" = {key = "w11-cifs-credentials";};
      "restic-vault-password" = {owner = "root";};
      "panix-smtp-password" = {owner = "root";};

      # User Email Keys (Declaratively owned by rik)
      "spectrum-smtp-password" = {owner = "rik";};
      "gmail-amphiboly-password" = {owner = "rik";};
      "gmail-amphibolybackup-password" = {owner = "rik";};
      "gmail-cornwall-password" = {owner = "rik";};
    };
  };

  # =========================================================================
  # 2. HARDWARE BOOTLOADER ENGINE & KERNEL PACKAGE UPDATES
  # =========================================================================
  #
  # =========================================================================
  # 1. System Bootloader Configurations (Preserved for standard installations)
  #
  boot = {
    # Forces your architecture to compile and track the absolute latest
    # stable upstream Linux release branch instead of standard LTS lines.
    kernelPackages = pkgs.linuxKernel.packages.linux_7_1;

    # Alternative option if you just want to track whatever the absolute
    # latest stable release is in nixpkgs automatically:
    # kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["btrfs" "cifs"];
  };

  networking.hostName = "datum";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  # =========================================================================
  #  3. DESKTOP ENVIRONMENT CONFIGURATION MATRIX
  # =========================================================================

  # Optimization tier for smooth interactive window scaling
  services.system76-scheduler.enable = true;
  # Required user context tracking backend for modern greeters and multi-user configurations
  services.accounts-daemon.enable = true;

  # =========================================================================
  # LAPTOP BATTERY AND POWER MANAGEMENT DEAMON (TLP + COSMIC PLATFORM FIXED)
  # =========================================================================

  # Block the default desktop power module to clear system locks
  services.power-profiles-daemon.enable = false;

  # Enable the core TLP configuration profile
  services.tlp = {
    enable = true;

    pd.enable = true;

    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # =========================================================================
  # 7. System User Management & Security Profiles
  # =========================================================================
  users.users.root.initialPassword = "nix";
  users.users.rik = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "input" "render" "networkmanager"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtSxcpUnDPA5EfZ0KmlDAjg7RzgqNoujzqOoQtQGuK4 rik@ambiguous"
    ];
    hashedPasswordFile = config.sops.secrets."rik-password-hash".path;
  };
  users.users.guest = {
    isNormalUser = true;
    description = "Guest User";
    # Essential desktop groups without administrative access:
    extraGroups = [
      "networkmanager"
      "video"
      "audio"
    ];
    # Sets an initial default password (e.g. "guest") so they can log in
    initialPassword = "guest";
  };

  # =========================================================================
  # 8. Optimized Global Environmental Variables
  # =========================================================================
  environment.sessionVariables = {
    NIXOS_OZONE_HLWM = "1"; # Forces Chromium/Electron apps to use native Wayland
    WLR_NO_HARDWARE_CURSORS = "1"; # Fixes invisible cursor rendering inside virtual machines
  };

  # =========================================================================
  # 9. Core system plumbing daemons and file utilities
  # =========================================================================
  # AUTOMATED SYSTEM SYSTEM MAINTENANCE LAYER

  # Disable native GC to avoid conflicts with nh
  nix.gc.automatic = false;

  # Enable nh helper
  programs.nh = {
    enable = true;
    flake = "/home/rik/Projects/datum/datum-config";

    # Optional: Automated periodic garbage collection
    clean = {
      enable = true;
      extraArgs = "--keep-since 4d --keep 3";
    };
  };

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = ["nix-command" "flakes"];
  };

  environment.systemPackages = with pkgs; [
    home-manager
    git
    wl-clipboard # native wayland clipboard manager
    cifs-utils # mount helper binaries required by your windows smb share
    tailscale # client cli companion for your mesh vpn daemon
    remmina
    freerdp
    rustic
    comma
    #   howdy
    v4l-utils
  ];

  # =========================================================================
  #  # 10. Filesystems
  # =========================================================================
  fileSystems = {
    # 5CD-RACK TAILSCALE SMB/CIFS NETWORK SHARES MATRIX
    "/mnt/5CDbackup" = {
      # Natively links to your static, secure Tailscale network rack share endpoint
      device = "//100.76.108.83/n/datum";
      fsType = "cifs";
      options = [
        # --- Core Automation & Network Startup Syncing Hooks ---
        "x-systemd.automount"
        "noauto"
        "nofail"
        "x-systemd.mount-timeout=30"
        "x-systemd.after=sops-nix.service"
        "x-systemd.idle-timeout=60" # Saves battery by dropping active connections when idle
        "_netdev"

        # --- Explicit Permissions Overrides (Matched from your Host) ---
        "uid=1000"
        "gid=100" # Uses the standard NixOS global users group ID
        "file_mode=0777" # Permissive file clearance matched from host string
        "dir_mode=0777" # Permissive directory clearance matched from host string

        # --- Cryptographic Security Keys Pipeline Link ---
        "credentials=/run/secrets/w11-cifs-credentials"

        # --- High-Performance Network Driver Options ---
        "vers=3.1.1" # Forces your host's crisp SMB 3.1.1 security protocol
        "cache=strict"
        "soft" # Prevents kernel panics if the network drops out mid-flight
        "nounix"
        "iocharset=utf8"
      ];
    };
    "/mnt/btrfs-root" = {
      device = "/dev/nvme0n1p3";
      fsType = "btrfs";
      options = ["subvolid=5" "noatime"];
    };
  };

  # =========================================================================
  # IDIOMATIC SYSTEMD FILE ATTRIBUTE PROVISIONS (DROPBOX SAFETY)
  # =========================================================================
  # Natively creates your path boundaries and locks down strict Btrfs properties
  systemd.tmpfiles.rules = [
    # Syntax: type path                  mode user group age argument
    # 'h' forces systemd to apply the strict +C (NOCOW/No-Compression) flag atomically [a]
    "d /home/rik/Dropbox 0700 rik users - -"
    "h /home/rik/Dropbox - - - - +C"
    # Automatically ensures /mnt/btrfs-root/.snapshots/home exists with
    # secure root-only permissions (0700) on every single boot sequence [a].
    "d /mnt/btrfs-root/.snapshots/home 0700 root root - -"
  ];

  # =========================================================================
  # 11. Enable built-in native PipeWire audio server
  # =========================================================================
  security.rtkit.enable = true; # Required for high-priority audio threads
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # =========================================================================
  # 12. MESH NETWORKING VIA TAILSCALE
  # =========================================================================
  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = ["tailscale0"];

  # =========================================================================
  # 13. Declarative Fonts System Configuration Mappings
  # =========================================================================
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      cascadia-code
      noto-fonts
      noto-fonts-cjk-sans
      dejavu_fonts
      (stdenv.mkDerivation {
        pname = "unifrakturmaguntia";
        version = "2017-03-19";
        src = fetchurl {
          url = "mirror://sourceforge/unifraktur/fonts/UnifrakturMaguntia.2017-03-19.zip";
          hash = "sha256-+j0JOeGYwP/FkhizdagYog7Kra9fw9OaIyKglavwz5o=";
        };
        nativeBuildInputs = [unzip];
        unpackPhase = "unzip $src";
        installPhase = ''
          mkdir -p $out/share/fonts/truetype
          find . -name "*.ttf" -exec install -Dm644 {} $out/share/fonts/truetype/ \;
        '';
      })
    ];
  };

  # =========================================================================
  # 14. CORE CUPS WEB SERVICE PRINTING LAYOUT
  # =========================================================================
  services.printing = {
    enable = true;

    # Injects the target compilation driver modules straight into the local CUPS backend loop
    drivers = with pkgs; [
      brlaser # Supports Brother MFC and HL layout frameworks natively
      hplipWithPlugin # Supports HP Color LaserJet print pipelines via proprietary hooks
    ];
  };
  # LOCAL NETWORK DISCOVERY AGENTS (AVAHI / MDNS CONFIGURATIONS)
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enables local resolution of '.local' network paths
    openFirewall = true; # Opens ports natively to prevent firewall block drops
  };
  # DOCUMENT SCANNING SUPPORT PLATFORM (SANE ENGINE)
  hardware.sane = {
    enable = true;
    extraBackends = [pkgs.sane-airscan]; # Enables driverless network scanning profiles
  };

  # =========================================================================
  # 15. BIOMETRIC FACIAL AUTHENTICATION INFRASTRUCTURE (GAZE ENGINE)
  # =========================================================================
  services.gaze = {
    enable = true;
    pam = {
      defaultServices = ["sudo" "swaylock" "hyprlock" "cosmic-greeter"];
    };
  };

  environment.etc."gaze/config.toml".text = ''
    [cameras]
    rgb = "v4l2src device=/dev/video0 ! video/x-raw,format=YUYV,width=160,height=120"
    ir = ""
    emitter_enabled = false
    dark_luma_threshold = 20

    [security]
    level = "medium"
    detector = "det_500m.onnx"
    recognizer = "w600k_mbf.onnx"
    rgb_threshold = 0.40
    ir_threshold = 0.40
    hybrid_policy = "fallback_on_dark"

    [liveness]
    enabled = true
    threshold = 0.80
    max_frames = 40

    [storage]
    encrypt_templates = false
  '';

  # # =========================================================================
  # # 15. BIOMETRIC FACIAL AUTHENTICATION INFRASTRUCTURE (HOWDY ENGINE)
  # # =========================================================================
  # services.linux-enable-ir-emitter.enable = true;
  # services.howdy = {
  #   enable = true;
  #   settings = {
  #     core = {
  #       # Fall back to password prompt immediately if the camera fails
  #       abort_if_no_camera = false;
  #     };
  #     video = {
  #       device_path = "/dev/video0";
  #       frame_width = 160;
  #       frame_height = 120;
  #       dark_threshold = 50;
  #       recording_plugin = "opencv";
  #     };
  #   };
  # };

  # security.pam.services.sudo.rules.auth.howdy-auth = {
  #   order = 10;
  #   control = "sufficient"; # Safe fallback behavior
  #   modulePath = "${pkgs.howdy}/lib/security/pam_howdy.so";
  # };

  # =========================================================================
  # 16. HARDENED LOCAL SYSTEM FIREWALL INFRASTRUCTURE (configuration.nix)
  # =========================================================================
  networking.firewall = {
    enable = true;
    allowPing = true; # Retained safely for local network diagnostics

    # -------------------------------------------------------------------------
    # CONDITIONAL OPEN PORTS (Active Across All Networks)
    # -------------------------------------------------------------------------
    # Whitelists your inbound connections universally, but relies on your local
    # authentication profiles to keep unauthorized public scans dropped.
    allowedTCPPorts = [
      22 # SSH Remote Login Daemon
    ];

    allowedUDPPorts = [
      5353 # mDNS (Avahi/Bonjour Local Service Device Discovery)
    ];

    # -------------------------------------------------------------------------
    # SECURITY LOCAL NETWORK OPTIMIZATION ALTERNATIVE:
    # -------------------------------------------------------------------------
    # If you want SSH and mDNS to drop instantly when you connect to public Wi-Fi,
    # comment out the global ports blocks above, uncomment your local home network
    # adapter interface string here, and let the system handle the context shift:
    #
    # interfaces."wlan0" = {
    #   allowedTCPPorts = [ 22 ];
    #   allowedUDPPorts = [ 5353 ];
    # };
  };

  # =========================================================================
  # 17. NATIVE REPRODUCIBLE BINARY CACHE VERIFICATION SYSTEMS
  # =========================================================================
  nix.settings = {
    # Establish the immutable global public keys needed to verify downloads
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
    ];

    # Secure administrative parameters to ensure smooth transitions
    trusted-users = ["root" "rik"];
  };

  # =========================================================================
  # MORE
  # =========================================================================
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  programs.kdeconnect.enable = true;

  # 99. Deployment Target Generation Cycle API Anchor
  system.stateVersion = "26.05";
}
