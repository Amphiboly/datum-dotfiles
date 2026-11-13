# pandoc, upstream's prebuilt Linux release instead of nixpkgs' source build.
#
# nixpkgs builds pandoc from Hackage inside haskellPackages, which tracks a
# Stackage LTS snapshot, so `pkgs.pandoc` sits at whatever that snapshot
# pins (3.7.0.2 as of 2026-11-13) while upstream moves on. Wanted here for
# the typst writer fix in 3.12.
#
# jgm's linux-amd64 tarball is a single statically linked executable (Lua
# and the server mode are compiled in), so it runs on NixOS as-is: no
# patchelf, no wrapper. `pandoc-server` and `pandoc-lua` are symlinks to it
# that select the mode by argv[0]. Strip/patchELF are turned off so the
# store copy is byte-for-byte upstream's.
#
# Caveat: nixpkgs' pandoc-crossref is built against nixpkgs' pandoc library
# version, not this one.
#
# UPDATING: bump `version`, then
#
#   nix build .#pandoc-bin
#
# fails with a hash mismatch reporting the real hash; paste it into `hash`
# and rebuild.
{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pandoc-bin";
  version = "3.14";

  src = fetchurl {
    url = "https://github.com/jgm/pandoc/releases/download/${finalAttrs.version}/pandoc-${finalAttrs.version}-linux-amd64.tar.gz";
    hash = "sha256-xfRyDN77P3vcXQcgLvV5/u8NE3B3PIc4BN2P2qjE8bg=";
  };

  nativeBuildInputs = [installShellFiles];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -a bin share $out/
    # pandoc only generates bash completion; zsh can use it via bashcompinit.
    installShellCompletion --cmd pandoc --bash <($out/bin/pandoc --bash-completion)
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/pandoc --version | head -1 | grep -qF ${lib.escapeShellArg "pandoc ${finalAttrs.version}"}
  '';

  meta = {
    description = "Universal document converter (upstream static binary)";
    homepage = "https://pandoc.org";
    changelog = "https://github.com/jgm/pandoc/releases/tag/${finalAttrs.version}";
    license = lib.licenses.gpl2Plus;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    mainProgram = "pandoc";
    platforms = ["x86_64-linux"];
  };
})
