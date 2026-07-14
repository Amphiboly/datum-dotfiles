# ~/Projects/datum-config/backups.nix
{
  config,
  pkgs,
  ...
}: {
  # 1. Register the backend keys in your system sops vault tracking array
  sops.secrets = {
    "panix-smtp-password" = {};
    "restic-vault-password" = {};
  };

  # 2. LOCAL BTRFS AUTOMATED SNAPSHOT MATRIX (BTRBK)
  services.btrbk = {
    instances.local = {
      onCalendar = "hourly";
      settings = {
        snapshot_preserve_min = "2d";
        snapshot_preserve = "24h 7d 4w";
        volume."/mnt" = {
          subvolume = "@home";
          snapshot_dir = ".snapshots/home";
        };
      };
    };
  };

  # 3. HIGH-PERFORMANCE RESTIC BACKUP TO YOUR WINDOWS 11 CIFS MOUNT
  services.restic.backups = {
    daily-backup = {
      initialize = true;
      paths = ["/home/rik"];
      exclude = ["/home/rik/Downloads" "/home/rik/.cache" "/home/rik/Dropbox"];

      repository = "/mnt/5CDbackup";
      passwordFile = config.sops.secrets."restic-vault-password".path;

      timerConfig = {
        OnCalendar = "02:00";
        Persistent = true;
      };
      pruneOpts = ["--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12"];
    };
  };

  # 4. PANIX OUTBOUND EMAIL TRANSIT PIPELINE (MSMTP)
  programs.msmtp = {
    enable = true;
    accounts = {
      default = {
        host = "mail.panix.com";
        port = 587; # Standard secure submission port
        tls = true;
        tls_starttls = true;
        auth = true;
        user = "rik"; # Your actual panix system username string
        passwordeval = "cat ${config.sops.secrets."panix-smtp-password".path}";
      };
    };
  };
}
