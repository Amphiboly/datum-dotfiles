#!/usr/bin/env bash
# example-diff.sh -- eyeball Noctalia/Umbriel configs against upstream's examples.
#
# Two questions, two modes:
#
#   ./example-diff.sh [noctalia|umbriel|both] [--user NAME] [--merged]
#       How does my config differ from the example in the locked input?
#
#   ./example-diff.sh [noctalia|umbriel|both] --since REV
#       What changed in the example between the input locked at git REV
#       (e.g. HEAD~1, last-cosmic, a hash) and the one locked now? The
#       "now" lock is the working-tree flake.lock, so this works right
#       after a `nix flake update`, before committing.
#
# Noctalia, mine-vs-example: the two files can't be diffed as they are.
# example.toml is hand-ordered by topic, while assets/<user>/noctalia.toml
# is a `noctalia config export`, which toml++ always writes in sorted key
# order. So both are run through the exporter of the *locked* noctalia
# (not the installed one, which lags until the next switch and could drop
# keys it doesn't know yet), each in a scratch XDG_CONFIG_HOME/STATE_HOME
# so neither the live config nor the state-dir settings.toml leaks in.
# Comments are lost on both sides. The export is `full` (built-in
# defaults filled in on both sides), so a hunk means a value really
# differs: example.toml spells out most defaults and the asset doesn't,
# and a `merged` export (--merged) mostly shows that instead.
#
# Umbriel, and both programs with --since: plain diffs. assets/rik/umbriel.toml
# follows the example's order and comments, and an example compared with an
# older copy of itself needs no normalising.

set -euo pipefail
cd "$(dirname "$0")"

usage() { sed -n '2,/^$/{s/^# \{0,1\}//;p}' "$0"; }

what=both since="" user=rik mode=full
while (($#)); do
  case $1 in
    noctalia | umbriel | both) what=$1 ;;
    --since) since=${2:?--since needs a git revision}; shift ;;
    --user) user=${2:?--user needs a name}; shift ;;
    --merged) mode=merged ;;
    -h | --help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

declare -A example=([noctalia]=example.toml [umbriel]=examples/config.toml)

# Locked "owner/repo/rev" for input $1, from the flake.lock JSON on stdin.
locked() {
  jq -r --arg i "$1" \
    '.nodes[.nodes.root.inputs[$i]].locked | "\(.owner)/\(.repo)/\(.rev)"'
}

# Store path of the source at "owner/repo/rev" $1. Already in the
# store for the current lock; fetched for an older one.
source_of() {
  nix flake prefetch --json "github:$1" | jq -r .storePath
}

normalise_noctalia() { # in out
  local root=$tmp/n.$RANDOM
  mkdir -p "$root/cfg/noctalia" "$root/state"
  cp "$1" "$root/cfg/noctalia/config.toml"
  XDG_CONFIG_HOME=$root/cfg XDG_STATE_HOME=$root/state \
    "$noctalia_bin" config export "$mode" >"$2"
}

# diff -y that doesn't trip set -e on "files differ".
show_diff() { # label-a a label-b b
  printf '%s  | %s\n' "$1" "$3"
  local rc=0
  diff -y --color="$colour"  \
   --label "$1" --label "$3" "$2" "$4"  \
   --suppress-common-lines  \
   || rc=$?
  ((rc <= 1)) || exit "$rc"
  ((rc == 1)) || echo "($1 and $3: no differences)"
}

colour=never
[[ -t 1 ]] && colour=always

run() { # program
  local p=$1 now ex
  now=$(locked "$p" <flake.lock)
  ex=$(source_of "$now")/${example[$p]}

  echo "=== $p: ${now##*/} ==="
  if [[ -n $since ]]; then
    local old
    old=$(git show "$since:flake.lock" | locked "$p")
    if [[ $old == "$now" ]]; then
      echo "(same $p rev at $since and now: nothing changed)"
      return
    fi
    show_diff "$p ${example[$p]} @ ${old##*/} ($since)" \
      "$(source_of "$old")/${example[$p]}" \
      "$p ${example[$p]} @ ${now##*/} (now)" "$ex"
    return
  fi

  local mine=assets/$user/$p.toml
  [[ -f $mine ]] || { echo "no $mine" >&2; exit 1; }
  if [[ $p == noctalia ]]; then
    noctalia_bin=$(nix build --no-link --print-out-paths --inputs-from . noctalia)/bin/noctalia
    normalise_noctalia "$ex" "$tmp/example.toml"
    normalise_noctalia "$mine" "$tmp/mine.toml"
    show_diff "example.toml (exported, $mode)" "$tmp/example.toml" \
      "$mine (exported, $mode)" "$tmp/mine.toml"
  else
    show_diff "${example[$p]}" "$ex" "$mine" "$mine"
  fi
}

{
  case $what in
    both) run noctalia; echo; run umbriel ;;
    *) run "$what" ;;
  esac
} | if [[ -t 1 ]]; then ${PAGER:-less} -R; else cat; fi
