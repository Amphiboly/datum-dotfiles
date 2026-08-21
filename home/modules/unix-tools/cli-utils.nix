# home/modules/unix-tools/cli-utils.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    # Shell tools
    bat
    eza
    fastfetch
    ripgrep
    dust

    # Nix utilities
    comma
    nvd
    nil
    alejandra

    # Foundational Unix Utility Layer left out by NixOS:
    btop
    e2fsprogs
    file
    tree
    unzip
    wget
    which

    # Just for fun (or the animal names)
    cmatrix
    cowsay
    tealdeer

    # Cloud storage and security
    _1password-cli
    _1password-gui
  ];
}
