# home/modules/unix-tools/gen-diff.nix
#
# gen-diff: what changed between two NixOS system generations, via
# `nix store diff-closures`. Read-only (it only follows the profile links in
# /nix/var/nix/profiles), so it lives in Home Manager rather than the system
# config.
#
#   gen-diff            previous generation -> current
#   gen-diff N          generation N -> current
#   gen-diff N M        generation N -> generation M
#   gen-diff -l         list generations with dates (also --list)
#   gen-diff -h         show purpose and usage (also --help)
#
# "Current" is the generation the system profile points at. That's normally
# the running system, but after `nh os boot` it's the one staged for the next
# reboot.
{pkgs, ...}: let
  genDiff = pkgs.writeShellApplication {
    name = "gen-diff";
    # No `nix` here on purpose: use the system's nix, so the diff comes from
    # the same version that built the generations.
    runtimeInputs = [pkgs.coreutils];
    text = ''
      profiles=/nix/var/nix/profiles
      usage="usage: gen-diff [-h | -l | N [M]]"

      usage_error() {
        echo "$usage" >&2
        exit 2
      }

      usage_help() {
        echo "Display differences between NixOS build generations"
        echo "$usage"
        exit
      }

      # Generation numbers, ascending.
      gens() {
        for g in "$profiles"/system-*-link; do
          n=''${g##*/system-}
          echo "''${n%-link}"
        done | sort -n
      }

      link() {
        local l="$profiles/system-$1-link"
        [[ -e $l ]] || { echo "gen-diff: no generation $1 (try gen-diff -l)" >&2; exit 1; }
        echo "$l"
      }

      current=$(readlink "$profiles/system")
      current=''${current#system-}
      current=''${current%-link}

      case "''${1-}" in
        -l | --list)
          for n in $(gens); do
            # stat the link itself: following it into the store gives 1970.
            when=$(date -d "@$(stat -c %Y "$profiles/system-$n-link")" '+%F %R')
            mark=""
            [[ $n == "$current" ]] && mark="  (current)"
            printf '%5s  %s%s\n' "$n" "$when" "$mark"
          done
          exit 0
          ;;
        -h | --help) usage_help ;;
        "" | [0-9]*) ;;
        *) usage_error ;;
      esac
      (( $# <= 2 )) || usage_error

      if (( $# >= 1 )); then
        from=$1
      else
        from=""
        for n in $(gens); do
          if (( n < current )); then from=$n; fi
        done
        [[ -n $from ]] || { echo "gen-diff: no generation before $current" >&2; exit 1; }
      fi
      to=''${2:-$current}

      if (( from > to )); then
        temp=$to
        to=$from
        from=$temp
      fi

      # Resolve into variables first: a failing $(...) inside nix's argument
      # list would not trip errexit, and nix would run with an empty path.
      from_link=$(link "$from")
      to_link=$(link "$to")
      echo "generation $from -> $to"
      nix store diff-closures "$from_link" "$to_link"
    '';
  };
in {
  home.packages = [genDiff];
}
