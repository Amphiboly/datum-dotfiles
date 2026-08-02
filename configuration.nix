# ~/Projects/datum-config/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  # 1. System Bootloader Configurations (Preserved for standard installations)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = ["btrfs" "cifs"];

  # 2. Virtual Hardware Graphics Acceleration Modules (Added for QEMU/Niri stability)
  boot.initrd.kernelModules = ["virtio_gpu"];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # 3. Base Networking Profiles
  networking.hostName = "datum";
  networking.networkmanager.enable = true;

  # 4. Regional Settings
  time.timeZone = "America/New_York";

  # 5. Core Native Wayland Compositor (Niri)
  programs.niri = {
    enable = true;
  };

  # =========================================================================
  #  6. COSMIC DESKTOP ENVIRONMENT CONFIGURATION MATRIX
  # =========================================================================
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.system76-scheduler.enable = true;
  services.accounts-daemon.enable = true;

  # =========================================================================
  #  HARDWARE BATTERY OPTIMIZATION VIA TLP
  # =========================================================================
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.upower.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
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
  nix.gc = {
    automatic = true;
    dates = "weekly"; # Wakes up automatically every week to clear dead packages [a]
    options = "--delete-older-than 7d"; # Safely preserves your last 7 days of rollbacks [a]
  };
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };

  environment.systemPackages = with pkgs; [
    home-manager
    git
    wl-clipboard # native wayland clipboard manager used by niri/ghostty
    cifs-utils # mount helper binaries required by your windows smb share
    tailscale # client cli companion for your mesh vpn daemon
    remmina
    freerdp
    rustic
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
        "x-systemd.mount-timeout=30"
        "x-systemd.idle-timeout=60" # Saves battery by dropping active connections when idle
        "_netdev"

        # --- Explicit Permissions Overrides (Matched from your Host) ---
        "uid=1000"
        "gid=100" # Uses the standard NixOS global users group ID
        "file_mode=0777" # Permissive file clearance matched from host string
        "dir_mode=0777" # Permissive directory clearance matched from host string

        # --- Cryptographic Security Keys Pipeline Link ---
        "credentials=/run/secrets/w11-cifs-password"

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
      options = [ "subvolid=5" "noatime" ];
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
        nativeBuildInputs = [ unzip ];
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
  # 15. BIOMETRIC FACIAL AUTHENTICATION INFRASTRUCTURE (HOWDY ENGINE)
  # =========================================================================
  services.howdy = {
    enable = true;
    control = "sufficient";

    settings = {
      core = {
        detection_notice = true;
        dark_threshold = 60;
      };
      video = {
        device_path = "/dev/v4l/by-path/pci-0000:00:14.0-usb-0:5:1.0-video-index0";
        frame_width = 640;
        frame_height = 480;
      };
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.policykit.exec") {
            return polkit.Result.YES;
        }
    });
  '';

##  # =========================================================================
##  #  15.BIOMETRIC FACIAL AUTHENTICATION INFRASTRUCTURE (GAZE ENGINE)
##  # =========================================================================
##  # 1. Compiles the custom gaze package from source since it's missing from stable channel attributes
##  security.pam.services = {
##    sudo.text = "auth sufficient pam_gaze.so";
##    login.text = "auth sufficient pam_gaze.so";
##    cosmic-lock.text = "auth sufficient pam_gaze.so";
##  };
##  # 2. Provisions the underlying systemd background service using a custom local builder block
##  systemd.services.gaze-daemon = let
##    # Inline packaging definition to fetch the missing gaze package attributes natively
##    gazePkg = pkgs.rustPlatform.buildRustPackage rec {
##      pname = "gaze";
##      version = "0.2.6";
##      src = pkgs.fetchFromGitHub {
##        owner = "GunduLabs";
##        repo = "gaze";
##        rev = "v${version}";
##        hash = "sha256-1k2/sbWEy1HBoNdtAoBjamnfXozZYKkhxCkrjaAE5Z0=";
##      };
##      cargoHash = "sha256-/VdUbKUTQvXC09FqHt97nlHRHp1P9v1xg/PNcN0vci0=";
##      nativeBuildInputs = with pkgs; [ pkg-config llvm ];
##      buildInputs = with pkgs; [
##        glib
##        pam
##        opencv
##        openssl
##        libclang
##        pango
##        cairo
##        gdk-pixbuf
##        gtk4
##        onnxruntime
##        gst_all_1.gstreamer
##        gst_all_1.gst-plugins-base
##      ];
##      LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
##      ORT_STRATEGY = "system";
##      ORT_USE_SYSTEM = "1";
##      ORT_LIB_DIR = "${pkgs.onnxruntime}/lib";
##      C_INCLUDE_PATH = "${pkgs.onnxruntime.dev}/include";
##      CPLUS_INCLUDE_PATH = "${pkgs.onnxruntime.dev}/include";
##    };
##  in {
##    description = "Gaze Biometric Facial Recognition Daemon";
##    wantedBy = [ "multi-user.target" ];
##    after = [ "systemd-modules-load.service" ];
##    path = [ gazePkg ];
##    
##    serviceConfig = {
##      ExecStart = "${gazePkg}/bin/gazed";
##      Type = "simple";
##      Restart = "always";
##      RestartSec = "2s";
##    };
##  };

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
