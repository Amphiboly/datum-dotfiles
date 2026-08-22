# modules/nixos/fonts.nix
{pkgs, ...}: {
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      cascadia-code
      noto-fonts
      noto-fonts-cjk-sans
      dejavu_fonts
      (stdenv.mkDerivation {
        pname = "unifrakturmaguntia";
        version = "2017-03-19";
        src = fetchurl {
          url = "mirror://sourceforge/unifraktur/fonts/UnifrakturMaguntia.2017-03-19.zip";
          hash = "sha256-+j0JOeGYwP/FkhizdagYog7Kra9fw9OaIyKglavwz5o=";
        };
        nativeBuildInputs = [unzip];
        unpackPhase = "unzip $src";
        installPhase = ''
          mkdir -p $out/share/fonts/truetype
          find . -name "*.ttf" -exec install -Dm644 {} $out/share/fonts/truetype/ \;
        '';
      })
    ];
  };
}
