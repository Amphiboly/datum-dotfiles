# home/modules/productivity/document-fonts.nix
#
# Typefaces for both general desktop use (fontconfig) and ConTeXt (OSFONTDIR).
#
# UnifrakturMaguntia isn't in nixpkgs, so it's built from the OFL-licensed
# copy vendored under assets/fonts/ (OFL permits redistribution, so this is
# safe to commit). msjh.ttc and times.ttf are proprietary Microsoft fonts
# licensed only for use on Windows systems Rik owns, NOT for redistribution
# -- their bytes must never enter git history or the Nix store. They live
# gitignored on disk at assets/fonts/, and Home Manager just symlinks to
# them out-of-store; OSFONTDIR points ConTeXt at the same directory.
{
  pkgs,
  lib,
  config,
  ...
}: let
  fontAssetsDir = ../../../assets/fonts;
  windowsFontsDir = config.home.homeDirectory + "/Projects/datum/datum-config/assets/fonts";
  windowsFontFiles = ["msjh.ttc" "times.ttf"];

  unifrakturMaguntia = pkgs.runCommand "unifraktur-maguntia" {
    nativeBuildInputs = [pkgs.unzip];
  } ''
    mkdir -p $out/share/fonts/truetype
    unzip -j ${fontAssetsDir}/UnifrakturMaguntia.2017-03-19.zip \
      'UnifrakturMaguntia.2017-03-19/UnifrakturMaguntia.ttf' \
      -d $out/share/fonts/truetype
  '';
in {
  fonts.fontconfig.enable = true;

  home = {
    packages = [pkgs.libertinus unifrakturMaguntia];

    file = lib.listToAttrs (map (name: {
        name = ".local/share/fonts/${name}";
        value.source = config.lib.file.mkOutOfStoreSymlink "${windowsFontsDir}/${name}";
      })
      windowsFontFiles);

    # ConTeXt (LMTX) doesn't read fontconfig; it scans OSFONTDIR itself, so
    # the same font set needs to be surfaced here too. Run `mtxrun
    # --generate` after any change before ConTeXt will pick it up.
    sessionVariables.OSFONTDIR = lib.concatStringsSep ":" [
      "${pkgs.libertinus}/share/fonts"
      "${unifrakturMaguntia}/share/fonts"
      windowsFontsDir
    ];
  };
}
