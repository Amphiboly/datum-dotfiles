# modules/nixos/alert-sandbox.nix
#
# systemd sandboxing for the two failure notifiers, status-email-alert@
# (backups.nix) and status-ntfy-alert@ (ntfy-alerts.nix). Added 2026-11-22,
# after lantian's "Hardening NixOS after I got hacked"; the option set is
# the article's, unchanged except where noted.
#
# These two are where it fits on datum: small units of our own that need
# almost nothing (read one journal, read one secret, make one outbound
# connection), unlike the root-level jobs (nightly upgrade, backups) whose
# whole point is broad access. Each unit file keeps what makes it work
# (DynamicUser, its credential, the systemd-journal group); this file only
# takes things away.
#
# Checking it: `systemd-analyze security status-ntfy-alert@x.service`
# scores a unit (it was 9.6 UNSAFE for both as root). If an option turns
# out to break something, SystemCallErrorNumber makes a forbidden syscall
# fail with EPERM in the unit's log instead of killing it silently.
_: let
  sandbox = {
    # No privilege gain, not even through setuid binaries like sudo.
    NoNewPrivileges = true;
    CapabilityBoundingSet = "";
    AmbientCapabilities = "";

    # Filesystem: everything read-only, /home and /root hidden; /run/secrets
    # isn't needed either, since the credential arrives via LoadCredential.
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateDevices = true;
    PrivateMounts = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";

    # Kernel and system state: look, don't touch.
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;

    # Less kernel surface. Both only make TCP connections (and nss lookups
    # over a Unix socket).
    LockPersonality = true;
    MemoryDenyWriteExecute = true; # fine: bash, curl, msmtp don't JIT
    RemoveIPC = true;
    RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service"
      "~@clock @cpu-emulation @debug @module @mount @obsolete @privileged @raw-io @reboot @swap"
    ];
    SystemCallErrorNumber = "EPERM";
  };
in {
  systemd.services."status-email-alert@".serviceConfig = sandbox;
  systemd.services."status-ntfy-alert@".serviceConfig = sandbox;
}
