# ziggity (github:simoarpe/ziggity), a keyboard-driven terminal UI for
# git written in Zig. Not in nixpkgs yet, so it's built here from source.
#
# Upstream also publishes a static musl binary per release, which would run
# as-is (like pkgs/pandoc-bin). A source build costs about the same to
# maintain and needs no trust in a prebuilt executable: nixpkgs has the Zig
# it needs (minimum_zig_version 0.17.1 in build.zig.zon).
#
# Zig dependencies: build.zig.zon pins libvaxis, which pins zigimg and,
# lazily, uucode. zig.fetchDeps runs `zig build --fetch` in a
# fixed-output derivation, so all of them sit behind a single `depsHash`.
# fetchAll = true because uucode is a *lazy* dependency, which the default
# `--fetch` (= "needed") skips (it gives a different, smaller output), yet
# libvaxis's build.zig asks for it.
#
# UPDATING: bump `version`, set both hashes to "" (lib.fakeHash), then
#
#   nix build .#ziggity
#
# Each run stops at the first hash mismatch and reports the real hash.
# Paste it in and rebuild. Source first, then deps. `depsHash` changes only
# when upstream moves a pin in build.zig.zon, but a stale value fails the
# same loud way, never silently. If `minimum_zig_version` goes past
# nixpkgs' zig_0_17, the build fails at configure; that is the point to
# switch `zig` (or to fall back to the release binary).
{
  lib,
  stdenv,
  fetchFromGitHub,
  zig_0_17,
}: let
  zig = zig_0_17;
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "ziggity";
    version = "0.62.0";

    src = fetchFromGitHub {
      owner = "simoarpe";
      repo = "ziggity";
      tag = "v${finalAttrs.version}";
      hash = "sha256-QnG99z3v9Eba3XAfH0+SSsDpp0D2UyQyIGDl00yW5wg=";
    };

    zigDeps = zig.fetchDeps {
      inherit (finalAttrs) pname version src;
      fetchAll = true;
      hash = "sha256-OjvuVDDu5l6pxx0Yew0TxqZQ6OsnPeU7x3ZMfnvhdLU=";
    };

    # zig.hook builds with --release=safe and installs to $out; only the
    # package cache has to be wired in. Since Zig 0.16 the global cache
    # keeps packages as <hash>.tar.gz under p/, which is what fetchDeps
    # captures, so it goes in as that p/ (as nixpkgs' anyzig does). Not
    # --system: that expects unpacked package directories. With every
    # pinned hash already in the cache zig never reaches for the network,
    # and the sandbox would stop it if it tried.
    nativeBuildInputs = [zig.hook];
    postConfigure = ''
      ln -s ${finalAttrs.zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
    '';

    meta = {
      description = "Keyboard-driven terminal UI for git, written in Zig";
      homepage = "https://github.com/simoarpe/ziggity";
      changelog = "https://github.com/simoarpe/ziggity/blob/v${finalAttrs.version}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = "ziggity";
      platforms = lib.platforms.linux;
    };
  })
