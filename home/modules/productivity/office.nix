# home/modules/productivity/office.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    glow
    libreoffice-fresh
    mdbook
    naps2
    pandoc
    (texlive.withPackages (ps:
      with ps; [
        scheme-infraonly
        context
        collection-luatex
      ]))
    zettlr
    zotero
  ];
}
