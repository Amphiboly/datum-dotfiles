# modules/nixos/sudo.nix
_: {
  # No "We trust you have received the usual lecture..." message. sudo
  # shows it once per user and records that in /var/db/sudo/lectured/,
  # which lives on the root filesystem. Since the root is wiped at every
  # boot (impermanence.nix, stage 3, 2026-11-11), the record went with it,
  # and the lecture came back after every reboot. Turning it off is simpler
  # than preserving a directory of empty marker files, and the message adds
  # nothing here: only rik is in wheel.
  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
