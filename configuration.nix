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
  # 6. GRAPHICAL NOCTALIA V5 INTERACTIVE GREETER MATRIX
  # =========================================================================
  imports = [
    inputs.noctalia-greeter.nixosModules.default
  ];
  services.displayManager = {
    enable = true;
    sessionPackages = [
      (pkgs.runCommandLocal "mangowc-session" {
          passthru.providedSessions = ["mango"];
        } ''
          mkdir -p $out/share/wayland-sessions
          cat << 'EOF' > $out/share/wayland-sessions/mango.desktop
          [Desktop Entry]
          Name=Mango
          Comment=MangoWC - High Performance Modal Wayland Tiling Compositor
          Exec=${pkgs.mango}/bin/mangowc
          Type=Application
          EOF
        '')
      pkgs.niri
    ];
  };
  environment.etc = {
    "mango/config.conf".text = config.home-manager.users.rik.xdg.configFile."mango/config.conf".text;
  };
  programs.noctalia-greeter = {
    enable = true;
    settings = {
      cursor = {
        theme = "Bibata-Modern-Ice";
        size = 24;
        path = "${pkgs.bibata-cursors}/share/icons";
      };
      keyboard = {
        layout = "us";
      };
    };
  };
  services.accounts-daemon.enable = true;

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
  # Automatically hardlink duplicate files in the background on a continuous loop [a]
  nix.settings.auto-optimise-store = true;

  environment.systemPackages = with pkgs; [
    git
    wl-clipboard # native wayland clipboard manager used by niri/ghostty
    cifs-utils # mount helper binaries required by your windows smb share
    tailscale # client cli companion for your mesh vpn daemon
    remmina
    freerdp
  ];

  #  # 10. Filesystems
  fileSystems = {
    # 5CD-RACK TAILSCALE SMB/CIFS NETWORK SHARES MATRIX
    "/mnt/5CDbackup" = {
      # Natively links to your static, secure Tailscale network rack share endpoint
      device = "//100.75.108.83/n/datum";
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
        "credentials=/run/secrets/w11-cifs-credentials"

        # --- High-Performance Network Driver Options ---
        "vers=3.1.1" # Forces your host's crisp SMB 3.1.1 security protocol
        "cache=strict"
        "soft" # Prevents kernel panics if the network drops out mid-flight
        "nounix"
        "iocharset=utf8"
      ];
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
  ];

  # 11. Enable built-in native PipeWire audio server
  security.rtkit.enable = true; # Required for high-priority audio threads
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  # 12. MESH NETWORKING VIA TAILSCALE
  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = ["tailscale0"];

  # 13. Declarative Fonts System Configuration Mappings
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono # Native 26.11 structure for JetBrainsMono Nerd Font
      cascadia-code
      noto-fonts
      noto-fonts-cjk-sans
      dejavu_fonts
    ];
  };

  # 14. CORE CUPS WEB SERVICE PRINTING LAYOUT
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

  # MORE
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  programs.kdeconnect.enable = true;

  # 99. Deployment Target Generation Cycle API Anchor
  system.stateVersion = "26.05";
}
