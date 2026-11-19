# luciole-scripts (github:CheikhNaro/luciole-scripts): extra right-click
# actions for Luciole, the file manager (modules/nixos/desktop/luciole.nix).
# Bash scripts forked from cfgnunes/nautilus-scripts, MIT. Upstream only
# offers ./install.sh, which writes into ~/.local/share/luciole/scripts;
# this runs that same installer into $out instead, so the layout is
# upstream's own. Installed for rik by home/modules/desktop-integration/
# luciole-scripts.nix.
#
# Pinned to a commit rather than a flake input on purpose: these scripts
# run with full access to whatever files they're given, and the repo is a
# young single-author one. A flake input would take whatever lands there
# in the nightly lock update; a pin means each update is read first.
#
# UPDATING: set `rev` to the new commit and `hash` to "" (lib.fakeHash),
# then `nix build .#luciole-scripts`; it stops at the hash mismatch and
# reports the real one. Before pasting it in, skim what changed upstream
# (`git log -p` in a clone), at least .common-functions.sh and the kept
# categories.
#
# What the installer produces, with `categories` below:
# - one launcher per category at the top of the scripts folder; those are
#   the entries Luciole shows (it lists at most 64, skips dotfiles);
# - the actions under .luciole-actions/<category>/, behind a menu
#   (.luciole-actions/menu.sh) drawn by luciole-dialog;
# - .common-functions.sh, .pkg-map.sh and .po/ translations, which every
#   action sources from the scripts folder.
#
# luciole-dialog (.dialog/, C++ on Wayland + cairo/pango) is built here.
# The installer would build it too, but discards make's output and falls
# back silently; built in buildPhase, a failure stops the build instead.
# It only draws the category menu: everything an action itself shows
# (questions, password entry, result lists) goes through zenity, which is
# why zenity is in `runtimeDeps` and not optional.
#
# Dependencies. Each action checks for its tools when it runs, and offers
# to install what's missing through the first package manager it finds.
# On NixOS that's `nix-env -iA nixos.<pkg>`, which fails here (no
# channels). A command already on PATH counts as present, so every tool
# the kept actions use goes into `runtimeDeps`, and the category launchers
# put that on PATH before the menu starts. The actions inherit it from
# there. Nothing lands on the user's own PATH. Luciole's own wrapper adds
# 7zz, which the archive actions find by name (`compgen -c 7z`).
# Not covered: Extract here's rarer formats (lzop, zpaq, dar, ...) beyond
# what libarchive's bsdtar reads; those would ask to install, and fail.
#
# bubblewrap is the actions' sandbox: each tool runs in `bwrap` with / read
# only, a cleared environment and ~/.config, ~/.ssh, ~/.gnupg and the like
# hidden. Without bwrap they run unsandboxed (a warning, nothing else).
{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  wayland,
  cairo,
  pango,
  libxkbcommon,
  # Base tools the helper library and the actions use throughout.
  coreutils,
  findutils,
  gnugrep,
  gnused,
  gawk,
  diffutils,
  file,
  procps,
  psmisc,
  xdg-utils,
  glib,
  zenity,
  bubblewrap,
  # Archives.
  gnutar,
  gzip,
  xz,
  zstd,
  libarchive,
  # Single actions.
  rhash,
  rdfind,
  exiftool,
  # Upstream category names (`./install.sh --list`). Must stay unique and
  # at most 64; the installer enforces both.
  categories ? [
    "Archive"
    "Checksum"
    "Directories and Files"
    "Rename files"
  ],
  # Single actions to leave out, as "<category>/<action file name>". The
  # installer only selects whole categories or groups, so these are deleted
  # after it runs; the category menu lists its folder as it finds it.
  # "Compare items" picks meld, diffpdf, ImageMagick or xxd by file type;
  # "Compare items (via Diff)" covers what's needed with plain diff.
  excludedActions ? [
    "Directories and Files/Compare items"
  ],
}: let
  runtimeDeps = [
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    diffutils
    file
    procps # pgrep
    psmisc # pstree: finding an action's child processes to stop them
    xdg-utils
    glib # gdbus: result and error notifications
    zenity
    bubblewrap
    gnutar
    gzip
    xz
    zstd
    libarchive # bsdtar: the 7z/zip actions check for it before 7z
    rhash # Compute all checksums
    rdfind # Find duplicate files
    exiftool # Show file metadata
  ];
in
  stdenv.mkDerivation {
    pname = "luciole-scripts";
    version = "0-unstable-2026-11-19";

    src = fetchFromGitHub {
      owner = "CheikhNaro";
      repo = "luciole-scripts";
      rev = "c22ea09ea4b4a8e3cef23f32c202e84f6d9ec858";
      hash = "sha256-tsdgs4+3nCHvVfldqeXn96NKZN0vhAAvqp6RZ+FoaFw=";
    };

    nativeBuildInputs = [pkg-config];
    buildInputs = [wayland cairo pango libxkbcommon];

    buildPhase = ''
      runHook preBuild
      make -C .dialog
      runHook postBuild
    '';

    # The installer resolves its target from XDG_DATA_HOME, and also copies
    # luciole-dialog to $HOME/.local/bin, which is thrown away here (the
    # menu finds the copy next to it first). --no-deps: its dependency
    # check only knows distro package managers.
    installPhase = ''
      runHook preInstall
      export HOME=$TMPDIR XDG_DATA_HOME=$out/share
      bash ./install.sh --yes --no-deps \
        ${lib.concatMapStringsSep " " (c: "--category ${lib.escapeShellArg c}") categories}

      # rm without -f: a name that no longer matches upstream fails the build.
      ${lib.concatMapStringsSep "\n" (a: "rm -- \"$out\"/share/luciole/scripts/.luciole-actions/${lib.escapeShellArg a}") excludedActions}

      # Category launchers: the top-level, non-hidden files. Each ends in
      # `exec .../menu.sh`; put the tools on PATH first.
      for hub in "$out"/share/luciole/scripts/*; do
        sed -i '/^exec /i export PATH=${lib.makeBinPath runtimeDeps}''${PATH:+:$PATH}' "$hub"
        grep -q '^export PATH=' "$hub"
      done
      runHook postInstall
    '';

    # The launcher names, for linking them in one by one (see the HM module).
    passthru = {inherit categories;};

    meta = {
      description = "Extra right-click actions for the Luciole file manager";
      homepage = "https://github.com/CheikhNaro/luciole-scripts";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
    };
  }
