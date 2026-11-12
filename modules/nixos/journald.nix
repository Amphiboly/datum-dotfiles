# modules/nixos/journald.nix
_: {
  # A deliberate ceiling for the persistent journal, instead of journald's
  # default: 10% of the filesystem, capped at 4 GB. The journal lives in
  # /persist/var/log (impermanence.nix) and takes up most of /persist.
  # When it reaches the cap, journald deletes the oldest archived files.
  # 2 GB is still weeks of history here. Set 2026-11-11, when the journal
  # was at 2.1 GB and climbing toward the default 4 GB.
  services.journald.settings.Journal.SystemMaxUse = "2G";
}
