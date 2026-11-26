# tera (github:shinokada/tera), a terminal UI for internet radio: search
# Radio Browser, keep favourite lists, play through mpv. Not in nixpkgs
# (the `tera` there is an unrelated R package) and upstream has no flake,
# so it's built here from source.
#
# Pure Go (upstream's release builds use CGO_ENABLED=0), so buildGoModule
# needs no native inputs. The ldflags copy upstream's .goreleaser.yaml:
# without -X main.version, `tera --version` says "dev".
#
# Playback: tera runs `mpv` from PATH and drives it over an IPC socket in
# $TMPDIR. mpv is appended to PATH (--suffix), so an mpv already on PATH,
# like Home Manager's programs.mpv with its config, wins; the bundled one
# only matters where no mpv is installed.
#
# UPDATING: bump `version`, set `hash` and `vendorHash` to "" (lib.fakeHash),
# then
#
#   nix build .#tera
#
# Each run stops at the first hash mismatch and reports the real hash.
# Paste it in and rebuild. Source first, then vendor. `vendorHash` changes
# only when go.mod/go.sum change, but a stale value fails loudly.
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  mpv,
}:
buildGoModule (finalAttrs: {
  pname = "tera";
  version = "3.11.1";

  src = fetchFromGitHub {
    owner = "shinokada";
    repo = "tera";
    tag = "v${finalAttrs.version}";
    hash = "sha256-EBp6PcGFXs9l8toBD6+Zl17FUMIoWwYwcSuoL3t5PVQ=";
  };

  vendorHash = "sha256-WugRMPpxj2rQjOrYfpuX58RhMyzLXxHJr8gWgeEJsbU=";

  subPackages = ["cmd/tera"];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  nativeBuildInputs = [makeWrapper];

  postInstall = ''
    wrapProgram $out/bin/tera --suffix PATH : ${lib.makeBinPath [mpv]}
  '';

  meta = {
    description = "Terminal internet radio player using mpv";
    homepage = "https://github.com/shinokada/tera";
    license = lib.licenses.mit;
    mainProgram = "tera";
    platforms = lib.platforms.linux;
  };
})
