# modules/nixos/filesystems.nix
_: {
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

  # IDIOMATIC SYSTEMD FILE ATTRIBUTE PROVISIONS (DROPBOX SAFETY)
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
}
