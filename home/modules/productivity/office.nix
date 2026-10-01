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
    zotero
  ];
}
