# COSMIC panel applet: a searchable cheat sheet of your actual COSMIC
# keybindings (read live from com.system76.CosmicSettings.Shortcuts).
# github:tomashaa/cosmic-ext-applet-cheatsheet -- a young community applet,
# not in nixpkgs, so packaged here the same way nixpkgs packages its other
# cosmic-ext-applet-* (see pkgs/by-name/co/cosmic-ext-applet-caffeine).
#
# Pinned to a commit on main rather than the v0.1.0 tag, which predates
# August's fixes. UPDATING: set `rev` and `version`, blank both hashes
# (hash = ""; cargoHash = "";), then `nix build .#cosmic-ext-applet-cheatsheet`
# twice -- each failure reports the real hash to paste in.
#
# Upstream's `just install` would run cargo itself (its install recipe
# depends on build-release), which can't work inside the sandbox, so the
# data files it installs are copied by hand in postInstall instead.
{
  lib,
  fetchFromGitHub,
  rustPlatform,
  libcosmicAppHook,
}: let
  appid = "io.github.tomashaa.CosmicExtCheatsheet";
in
  rustPlatform.buildRustPackage {
    pname = "cosmic-ext-applet-cheatsheet";
    version = "0.1.0-unstable-2026-09-21";

    src = fetchFromGitHub {
      owner = "tomashaa";
      repo = "cosmic-ext-applet-cheatsheet";
      rev = "a61eeba8dcb249ab80d0e1d9d770a41713d17d71";
      hash = "sha256-3vcz7SDlfFl5xtgaXtvsWEuhn+zzfJyNj+gCYQiUapo=";
    };

    cargoHash = "sha256-7iQE3vP8JORJOT7ouDPLW5UFxH9OpRY885DfUsF57eg=";

    # Wraps the binary with the env libcosmic needs at runtime (Wayland and
    # xkbcommon libraries, XDG data dirs) and supplies its build inputs.
    nativeBuildInputs = [libcosmicAppHook];

    postInstall = ''
      install -Dm644 data/${appid}.desktop -t $out/share/applications
      install -Dm644 data/${appid}.metainfo.xml -t $out/share/metainfo
      install -Dm644 data/icons/hicolor/scalable/apps/${appid}-symbolic.svg \
        -t $out/share/icons/hicolor/scalable/apps
    '';

    meta = {
      description = "COSMIC panel applet showing a searchable cheat sheet of your keyboard shortcuts";
      homepage = "https://github.com/tomashaa/cosmic-ext-applet-cheatsheet";
      license = lib.licenses.gpl3Only;
      mainProgram = "cosmic-ext-applet-cheatsheet";
      platforms = lib.platforms.linux;
    };
  }
