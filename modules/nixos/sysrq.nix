# modules/nixos/sysrq.nix
_: {
  # Magic SysRq, fully enabled. The kernel catches Alt+SysRq+<key> in its
  # own input layer, before libinput and the compositor see anything, so it
  # still works when Umbriel has stopped responding to input (as on
  # 2026-11-25, after leaving a fullscreen sdl-freerdp session).
  #
  # On this keyboard SysRq is Alt+PrtSc, no Fn (checked 2026-11-25 with
  # Alt+PrtSc+H, which logs "sysrq: HELP" at any setting). Keep Alt held,
  # tap PrtSc, then tap each key in turn.
  #
  # The way out without the power button, about a second between keys:
  #   R  take the keyboard out of raw mode
  #   E  SIGTERM to all processes      I  SIGKILL to all processes
  #   S  sync filesystems              U  remount all read-only
  #   B  reboot
  # Before rebooting, W (tasks stuck in uninterruptible sleep) and T (all
  # tasks) dump state into the kernel log, which is persistent here
  # (journald.nix), so the previous boot's `journalctl -k -b -1` keeps it.
  #
  # NixOS sets 16 (sync only) by default. 1 also enables those dumps and
  # C (deliberate crash); on a laptop, anyone at the keyboard can already
  # hold the power button, so a narrower mask buys nothing here.
  boot.kernel.sysctl."kernel.sysrq" = 1;
}
