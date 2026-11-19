# home/modules/desktop-integration/luciole-scripts.nix
#
# Extra right-click actions in Luciole (Scripts menu), from
# CheikhNaro/luciole-scripts, built in pkgs/luciole-scripts; what they are,
# which tools they get and how to update them is there. Luciole itself is
# system-wide (modules/nixos/desktop/luciole.nix).
#
# Kept: Archive, Checksum, Directories and Files, Rename files (46 actions
# behind 4 menu entries), since 2026-11-19. Left out on purpose: Open with,
# Security and Backup, Clipboard; "Compare items" (the via-Diff one stays);
# and everything outside upstream's recommended set (audio/video, image,
# document, encryption, links, network). To change the set, pass
# `categories` or `excludedActions` to the callPackage below.
#
# Luciole reads ~/.local/share/luciole/scripts and trusts a script only if
# it and that folder (and its parent) are owned by you or root and not
# writable by group or others. Store files are root-owned and read-only,
# and Luciole follows symlinks (src/platform/program_launcher.cpp), so
# links into the store pass.
#
# Linked entry by entry, not as one folder, so that the folder stays a
# real one and a script of your own can still be dropped in next to these
# (upstream's "custom actions"). But not file by file either, which is
# what `recursive = true` does, and which was the first version: the
# category menu lists a category's actions with `find <dir> -type f`, and
# -type f doesn't match symlinks, so every menu came up empty ("No action
# found", printed where nobody sees it). With .luciole-actions linked as
# one directory, find starts below the link, in the store, where the
# actions are regular files.
{
  lib,
  pkgs,
  ...
}: let
  scripts = pkgs.callPackage ../../../pkgs/luciole-scripts {};
  # The category launchers, plus what the launchers and actions read from
  # beside them. The installer's manifest isn't needed.
  entries = scripts.categories ++ [".luciole-actions" ".common-functions.sh" ".pkg-map.sh" ".po"];
in {
  xdg.dataFile = lib.genAttrs (map (e: "luciole/scripts/${e}") entries) (path: {
    source = "${scripts}/share/${path}";
  });
}
