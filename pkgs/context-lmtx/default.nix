# ConTeXt LMTX, fetched live from upstream at build time instead of TeX
# Live's yearly-frozen `texlive.context`.
#
# ConTeXt LMTX has no dated releases: `mtxrun --update` (what install.sh
# drives, and what `raw` below reimplements) always grabs whatever is
# "current" on lmtx.pragma-ade.com. There is nothing to pin to except "what
# was current when this was last built" -- which is genuinely how Rik
# already tracks ConTeXt elsewhere (an email arrives on every upstream
# update, weekly to every two months).
#
# UPDATING: bump `version` below to today's date, then run
#
#   nix build .#context-lmtx
#
# It will fail with a hash mismatch reporting the actual new hash; paste
# that into `raw`'s outputHash and rebuild.
#
# Two derivations, deliberately:
#
# `raw` is a fixed-output derivation: it downloads the bootstrap installer
# (a prebuilt `mtxrun` used only to fetch everything else -- texmf-context,
# fonts, modules, and the real platform binaries -- see install.sh inside
# the bootstrap zip) and runs the network install, but copies only the
# untouched downloaded tree into $out. Fixed-output derivations are not
# allowed to reference other store paths in their content, so the bootstrap
# `mtxrun` is patched and run from a scratch copy outside $out, never
# inside it -- $out ends up byte-for-byte what upstream shipped.
#
# The outer derivation takes that tree, is a normal (non-fixed-output,
# network-free) derivation, and does the actual NixOS-specific work:
# patchelf on the downloaded `luametatex`/`luatex` (built for a generic
# Linux dynamic linker NixOS doesn't have), and wrapper scripts exposing
# `context`/`mtxrun`/`luametatex`/`luatex` on $out/bin. It needs no manual
# hash bumping -- it's addressed by its inputs, so it updates automatically
# whenever `raw` does.
#
# The $out/bin wrappers deliberately do NOT use makeWrapper's usual `exec -a`
# trick: LuaMetaTeX derives its own texmf root by walking two directories up
# from wherever it thinks it was invoked from, and expects that to land two
# levels below the install root (tex/texmf-linux-64/bin/<name>). A flat
# `$out/bin/<name>` wrapper (one level below $out) throws that off by
# exactly one directory and it silently fails to find texmfcnf.lua. Instead
# each wrapper prepends the real, correctly-nested bin/ directory to PATH
# and execs the bare command name, which is the one invocation style
# confirmed (by hand, against a real build of this derivation) to preserve
# correct self-location.
{
  lib,
  stdenv,
  autoPatchelfHook,
  curl,
  cacert,
  unzip,
}: let
  raw = stdenv.mkDerivation {
    pname = "context-lmtx-raw";
    version = "2026-08-30";

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-ZpE71V931MpJYXZTbECZ0+nZAZ8viCkIMwWW6buBWqw=";

    nativeBuildInputs = [autoPatchelfHook curl cacert unzip];

    dontUnpack = true;
    dontConfigure = true;
    dontInstall = true;
    # autoPatchelfHook's *automatic* fixup pass would otherwise patch the
    # downloaded luametatex/luatex in place and leak a glibc reference into
    # this fixed-output derivation's content. Only the explicit, scratch-only
    # `autoPatchelf` call below (never touching $out) should run here.
    dontAutoPatchelf = true;

    buildPhase = ''
      runHook preBuild

      curl -fsSL -o bootstrap.zip https://lmtx.pragma-ade.com/install-lmtx/context-linux-64.zip
      mkdir -p scratch
      unzip -q bootstrap.zip -d scratch

      # patch a scratch copy only -- it must never end up in $out
      chmod +x scratch/bin/mtxrun
      autoPatchelf scratch/bin/mtxrun

      (
        cd scratch
        export PATH="$PWD/bin:$PATH"
        ./bin/mtxrun --script ./bin/mtx-install.lua --update \
          --server=lmtx.pragma-ade.com,lmtx.pragma-ade.nl,lmtx.contextgarden.net \
          --instance=install-lmtx --platform=linux-64 --erase
      )

      mkdir -p $out
      cp -r scratch/tex $out/tex
      cp scratch/installation.pdf $out/

      runHook postBuild
    '';
  };
in
  stdenv.mkDerivation {
    pname = "context-lmtx";
    inherit (raw) version;

    src = raw;

    nativeBuildInputs = [autoPatchelfHook];

    dontUnpack = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r $src/tex $out/tex
      chmod -R u+w $out/tex

      # luametatex answers to mtxrun/context/luametatex depending on its own
      # (correctly self-located) binary name, and luatex is its own separate
      # engine (MkIV, `context --luatex`) -- all four are real, directly
      # invocable names under tex/texmf-linux-64/bin already.
      mkdir -p $out/bin
      for prog in context mtxrun luametatex luatex; do
        cat > $out/bin/$prog <<'WRAPPER'
      #!/bin/sh
      self=$(readlink -f "$0")
      selfdir=$(dirname "$self")
      export TEXMFCACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/context-lmtx"
      export PATH="$selfdir/../tex/texmf-linux-64/bin:$PATH"
      exec "$(basename "$self")" "$@"
      WRAPPER
        chmod +x $out/bin/$prog
      done

      runHook postInstall
    '';

    meta = {
      description = "ConTeXt LMTX, tracking upstream's rolling releases instead of TeX Live's yearly snapshot";
      homepage = "https://wiki.contextgarden.net/ConTeXt_Standalone";
      license = lib.licenses.gpl2Plus;
      platforms = ["x86_64-linux"];
      mainProgram = "context";
    };
  }
