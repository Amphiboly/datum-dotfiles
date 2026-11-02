# home/modules/productivity/office.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    glow
    just
    libreoffice-stable
    lilypond-unstable-with-fonts
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
    # zotero: Zotero 10 runs on Firefox ESR 140, which is end-of-life, so
    # nixpkgs marks it insecure and refuses to evaluate it. Waiting for a
    # Zotero on a supported ESR rather than allowing it. See KNOWN-ISSUES.md.
    #  zotero
  ];
}
