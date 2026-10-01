# home/modules/productivity/office.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    glow
    just
    libreoffice-stable
    mdbook
    naps2
    pandoc
    # Real ConTeXt LMTX, fetched from upstream at build time -- see
    # ../../../pkgs/context-lmtx for why this replaces texlive.context
    # (frozen to TeX Live's yearly release) and how to update it.
    (pkgs.callPackage ../../../pkgs/context-lmtx {})
    typst
    zathura
    zettlr
    # zotero: build broken on unstable since nixpkgs dropped Firefox ESR
    # 140, which Zotero 10 requires (NixOS/nixpkgs#568692). Re-enable once
    # NixOS/nixpkgs#569006 ("zotero: fix build by reviving Firefox 140")
    # has merged and reached nixos-unstable.
    #  zotero
  ];
}
