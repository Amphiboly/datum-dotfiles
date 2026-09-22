# home/modules/productivity/syncthing-rik.nix
#
# This user's actual Syncthing wiring: ~/Projects shared bidirectionally
# with nostrum.
#
# nostrum's device ID below is a placeholder -- Syncthing isn't set up on
# nostrum yet. Once it is, grab its ID from that machine's GUI (Actions >
# Show ID) and replace the value; until then this folder just sits local
# and unshared, since Syncthing rejects a malformed device ID rather than
# failing the build.
_: {
  services.syncthing.settings = {
    devices.nostrum = {
      id = "REPLACE-WITH-NOSTRUMS-DEVICE-ID";
    };

    folders.projects = {
      id = "projects";
      path = "~/Projects";
      devices = ["nostrum"];

      # Cheap insurance against a bad sync clobbering irreplaceable draft
      # content -- keeps a thinning history of changed/deleted files.
      versioning.type = "staggered";

      ignorePatterns = [
        # Version control -- never sync .git directly; each machine keeps
        # its own clone/checkout and syncs via git push/pull instead.
        "**/.git"

        # External git storage for document projects (Projects/git/<docname>
        # instead of an in-tree .git). Same reasoning as .git above.
        "/git"

        # Nix build outputs and dev-shell caches
        "**/result"
        "**/result-*"
        "**/.direnv"

        # ConTeXt/TeX build byproducts
        "**/*.log"
        "**/*.tuc"
        "**/*.top"
        "**/*.synctex.gz"
        "**/*-tmp.pdf"

        # LibreOffice/ODT lock and backup files
        "**/.~lock.*#"
        "**/*.bak"

        # Editor swap/backup/tmp files
        "**/*.swp"
        "**/*.swo"
        "**/*~"
        "**/tmp"
        "**/.tmp"

        # Claude Code local, per-machine permission state -- deliberately
        # gitignored, shouldn't leak between machines any more than it
        # does between commits
        "**/.claude/settings.local.json"
      ];
    };
  };
}
