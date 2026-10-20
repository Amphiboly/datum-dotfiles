# home/modules/productivity/office.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    glow
    just
    libreoffice-stable
    mdbook
    # naps2: build broken on unstable since nixpkgs moved patchelf from
    # 0.15.2 to 0.19.2 (between the 2026-10-15 and 2026-10-17 locks).
    # patchelf 0.19.2 aborts (`Assertion splitIndex == -1 failed`) adding
    # an rpath to `crossgen` in the prebuilt .NET 2.1 arm64 runtime pack
    # that naps2's NuGet deps pull in. naps2 itself is unchanged at 8.3.2.
    # Re-enable once `nix build nixpkgs#naps2` succeeds (or the cache has
    # it). See KNOWN-ISSUES.md.
    #  naps2
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
