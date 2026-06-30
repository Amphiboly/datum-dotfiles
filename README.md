# 💻 datum-dotfiles

A modular, declarative NixOS and Home Manager configuration for system `datum`, built with a phased sandbox-to-hardware deployment strategy. 

This repository centralizes my custom desktop environments, text editors, development tooling, and data layouts, bridging the gap between pure declarative architecture and mutable configurations.

---

## 🏗️ Deployment Strategy

To safely transition to a custom, minimal Wayland environment without traditional Desktop Environments (GNOME/KDE), the installation is managed in three distinct phases:

1. **Stage 1: Core Base (Virtual Sandbox)**
   * **Target:** 4-core, 12GB QEMU/KVM `virt-manager` VM on a Fedora host.
   * **Scope:** Minimal bootable TUI login (`tuigreet`), basic networking/SSH, core CLI utils, and Zsh shell ecosystem.
2. **Stage 2: Graphical Stack & Compositors**
   * **Scope:** Specialized Wayland testing. Provides modular switches to alternate between **Niri** (with Noctalia V5 shell/greeter) and the **Mango WC** compositor.
3. **Stage 3: Laptop Bare-Metal Deployment**
   * **Target:** HP Spectre x360 13t (i7-7500U Kaby Lake, HD 620, 16GB RAM, 512GB SSD).
   * **Scope:** Hardware optimizations (VA-API video acceleration, TLP power management, accelerometer), Lanzaboote Secure Boot, CUPS network printing, and full desktop productivity applications.

---

## 🗂️ Repository Architecture

This repository holds both pure Nix declarations and standard runtime dotfiles. XDG configurations are symmetrically linked into the user space via Home Manager's `mkOutOfStoreSymlink` mechanism, allowing configurations to be edited directly at runtime without requiring a full system rebuild during testing.

```text
~/dotfiles/
├── btop/           # Resource monitor theme and layouts
├── fastfetch/      # Neo-fetch alternative system specs dashboard
├── ghostty/        # Terminal emulator profiles and fonts
├── helix/          # Text editor configs & LSP keybindings
├── naps2/          # SANE document scanner configurations
├── niri/           # Window manager geometry, layouts, and binds
├── starship/       # Shell prompt configuration (starship.toml)
├── zathura/        # Document/PDF viewer configurations
├── zed/            # Zed editor (GUI/CLI) preferences
├── Zettlr/         # Academic markdown journal preferences
├── zsh/            # Antidote plugin configurations and .zshrc
└── README.md       # This reference documentation
```

---

## 🔒 Storage & Data Partitioning Blueprint

The system architecture utilizes **Disko** for precise, reproducible layout definitions:
* **Boot:** Separate dedicated EFI partition.
* **Root Volume:** LUKS-encrypted Btrfs container encapsulating:
  * System root and user `/home` subvolumes.
  * Dedicated snapshot targets for `btrbk` and scheduled `restic` backups.
  * **Dropbox Isolation:** A specialized, separate Btrfs subvolume mounted directly to `~/Dropbox` to isolate heavy consumer-cloud database sync behaviors from baseline system snap-points.
  * **Hibernation Swapfile:** A `~18GB` physical swapfile embedded inside the encrypted Btrfs container to facilitate reliable, secure laptop hibernation. Coupled with in-memory **ZRAM** for active compilation caching.

---

## 🚀 Bootstrap Command Reference

When spinning up the clean NixOS Live ISO environment inside the VM sandbox to execute your deployment:

### 1. Mount Host Plan9 File Share
To bypass the need for an early remote network clone inside the Live ISO, mount your host's shared directory via the Plan9 virtual transport protocol:
```bash
# Create the local mounting target inside the Live ISO environment
sudo mkdir -p ~/dotfiles

# Mount the virt-manager bridge using the defined hardware tag
sudo mount -t 9p -o trans=virtio,version=9p2000.L,msize=1048576,rw dotfiles_share ~/dotfiles
```
*(Note: `msize=1048576` optimizes transmission block sizes for significantly faster file execution).*

### 2. Format & Provision Block Storage via Disko
```bash
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode destroy,format,mount ~/dotfiles/nix/disko.nix
```

### 3. Apply the System Flake Install
```bash
nixos-install --flake ~/dotfiles#datum
```
