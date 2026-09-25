# home/modules/unix-tools/cli-utils.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    # Shell tools
    bat
    dust
    eza
    fastfetch
    jq
    ripgrep
    yazi

    # Nix utilities
    alejandra
    comma
    deadnix
    nil
    nix-olde
    nvd
    statix

    # Version control
    gh

    # Foundational Unix Utility Layer left out by NixOS:
    btop
    e2fsprogs
    file
    gnumake
    tree
    unzip
    wget
    which

    # Just for fun (or the animal names)
    cmatrix
    cowsay
    tealdeer

    # 1Password lives in modules/nixos/onepassword.nix instead: the GUI needs
    # a setuid browser-support helper and a polkit policy that a home.packages
    # entry cannot provide, and both programs._1password{,-gui} already put
    # their packages in environment.systemPackages.
  ];
}
