# home/modules/unix-tools/python.nix
#
# A bare python3 on PATH, for one-off scripts (and Claude Code's quick text
# edits). The store already holds this interpreter as a dependency of other
# packages, but nothing in the store is on PATH unless a profile links it.
#
# Not a development environment: there is no writable site-packages, so
# `pip install` doesn't work here. Projects bring their own interpreter and
# libraries through a dev shell; for a few libraries that should always be
# at hand, switch this to python3.withPackages (ps: [ ... ]).
{pkgs, ...}: {
  home.packages = [pkgs.python3];
}
