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
    which

    # wget2: faster/HTTP2-capable successor to wget. Nixpkgs only installs
    # the wget2 binary, so symlink it as `wget` too -- scripts and muscle
    # memory both key on that name, and a shellAlias wouldn't cover scripts.
    (wget2.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        ln -s $out/bin/wget2 $out/bin/wget
      '';
    }))

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
