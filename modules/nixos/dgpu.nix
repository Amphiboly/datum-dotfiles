# modules/nixos/dgpu.nix
#
# The NVIDIA MX150 (GP108, 0000:01:00.0). Nothing on datum uses it:
# Umbriel and everything else render on the Intel iGPU (i915). Until
# 2026-11-26 there was no config for it, so the kernel auto-loaded
# `nouveau` for it.
_: {
  # nouveau is blacklisted because its probe crashes on every boot.
  #
  # From 2026-11-24 every boot logged a kernel oops at about +80 s:
  # page fault in ioread32 under gp102_acr_wpr_patch, called from
  # nouveau_drm_probe, in a (udev-worker) loading the module. The oops
  # kills that task while it holds the GPU's device lock, and the lock is
  # never released. Nothing notices while the system runs, but anything
  # that walks all devices waits on that lock forever:
  #   - reboot/power-off: the kernel's device_shutdown() hangs after
  #     journald has stopped, so the journal of that boot looks clean
  #     (hard power-off needed 2026-11-26);
  #   - suspend: the boot of 2026-11-24 ends at "Performing sleep
  #     operation 'suspend'" with no resume.
  # The oops itself survives in /var/lib/systemd/pstore (EFI pstore).
  #
  # Before that it was already going wrong: on 2026-11-19 (kernel 7.3.4)
  # nouveau saw "fb: 2048 MiB GDDR5"; from 2026-11-20 (7.3.5) it reports
  # "fb: 0 MiB" and PRIVRING MMIO read faults. It began crashing on
  # 2026-11-24 with no kernel change, so it is either a nouveau regression
  # or the card failing; this doesn't tell which.
  #
  # Removing it: drop this line, boot, and check
  # `journalctl -k -b | rg 'nouveau|BUG:'` shows a non-zero fb size and no
  # oops.
  #
  # The device stays on the PCI bus without a driver. Whether it then
  # still reaches a low power state is the open item "MX150 power state on
  # battery" in KNOWN-ISSUES.md.
  boot.blacklistedKernelModules = ["nouveau"];
}
