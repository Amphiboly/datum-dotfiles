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
  boot.blacklistedKernelModules = ["nouveau"];

  # Power the card off completely (D3cold). Without a driver the kernel
  # leaves it at full power: `power/control` defaults to `on`, so runtime
  # PM never runs, and the card sat in D0 (with nouveau it only reached
  # D3hot). Two devices need `auto`:
  #   - the GPU (01:00.0), so it counts as idle. With no driver, PCI
  #     runtime suspend only marks it "suspended" and doesn't change its
  #     power state, but that lets the parent sleep;
  #   - its PCIe root port (00:1c.0), which has ACPI power resources for
  #     D3hot (_PR3). When the port suspends, the firmware switches those
  #     off and the GPU behind it loses power: both report D3cold.
  # Verified by hand 2026-11-26 (sysfs writes, then power_state and the
  # port's firmware_node/power_resources_D3hot/*/resource_in_use = 0).
  # Check after boot:
  #   cat /sys/bus/pci/devices/0000:0{0:1c,1:00}.0/power_state
  # Matched by PCI address, which is fixed on this board; if the
  # hardware changes, these rules simply match nothing.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:01:00.0", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:1c.0", ATTR{power/control}="auto"
  '';
}
