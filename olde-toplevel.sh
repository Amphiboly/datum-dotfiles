#!/usr/bin/env bash
# Filter nix-olde's report down to top-level packages: the ones that land in
# environment.systemPackages or some user's home.packages, whether listed
# there by hand or added by an enabled module (programs.*.enable etc.).
# Transitive dependencies -- python modules, libraries -- are dropped.
#
#   nix-olde -f . | ./olde-toplevel.sh
#   ./olde-toplevel.sh saved-olde-output.txt
#   ./olde-toplevel.sh --inputs
#
# --inputs covers what nix-olde can't see: packages taken from their own
# flake inputs (noctalia, umbriel) rather than nixpkgs. Their version
# string rarely moves; what changes is the git revision in flake.lock, so
# each github input's locked rev is compared with upstream's: with the
# branch flake.nix follows, or, for an input pinned to a release tag, with
# the newest release tag.
#
# Must run from the repo root (it evaluates the flake in `.`). HOST_ATTR
# selects a nixosConfigurations entry other than datum.
#
# Needs: bash, nix, awk and GNU date; --inputs also needs git, grep and
# GNU sort (-V). nix-olde
# produces the report this reads but is not called here, so it only has
# to be installed wherever that report is made. jq is not used: flake.lock
# is parsed with `nix eval` (builtins.fromJSON). Optional: gh, for
# --inputs' "behind by N commits" counts.
set -euo pipefail

host=${HOST_ATTR:-datum}

if [[ ${1:-} == --inputs ]]; then
  # One "name type owner/repo ref rev lastModified" line per direct input.
  # Only github inputs carry a rev that ls-remote can check; the rest
  # (nixpkgs is a channel tarball, which nix-olde already covers) are
  # reported as skipped.
  #
  # The ref comes from the lock's `original` entry: what flake.nix asked
  # for (a branch like noctalia's `cachix`, or a tag like lanzaboote's
  # `v1.2.0`). The `locked` entry carries no ref, so reading it there
  # compared every input with the default branch.
  # shellcheck disable=SC2016 # the ${...} below is Nix interpolation
  nix eval --impure --raw --expr '
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
      line = name: node: let
        n = lock.nodes.${node};
        l = n.locked;
      in
        "${name} ${l.type} ${l.owner or "-"}/${l.repo or "-"} "
        + "${n.original.ref or "-"} ${l.rev or "-"} ${toString l.lastModified}";
    in builtins.concatStringsSep ""
      (map (s: s + "\n")
        (builtins.attrValues (builtins.mapAttrs line lock.nodes.root.inputs)))
  ' | while read -r name type repo ref rev modified; do
    locked=$(date -u -d "@$modified" +%F)
    if [[ $type != github ]]; then
      printf '%-20s %s  skipped (%s input)\n' "$name" "$locked" "$type"
      continue
    fi
    url="https://github.com/$repo"

    # Tag pin: a tag doesn't move, so "behind the branch" says nothing.
    # Report whether a newer release tag exists instead. Release tags are
    # plain versions (v1.2.0, 1.2.0); pre-releases (v1.3.0-rc1) and other
    # tag names are ignored. ls-remote lists an annotated tag twice: as
    # the tag object and peeled (^{}) as the commit, which is what
    # flake.lock records.
    if [[ $ref != - ]] && tags=$(git ls-remote --tags "$url") \
      && grep -q "refs/tags/$ref\(^{}\)\?\$" <<<"$tags"; then
      tagrev=$(awk -v t="refs/tags/$ref" '$2 == t { r = $1 } $2 == t "^{}" { p = $1 }
        END { print (p != "" ? p : r) }' <<<"$tags")
      latest=$(awk '{ sub(/^refs\/tags\//, "", $2); sub(/\^\{\}$/, "", $2); print $2 }' <<<"$tags" \
        | grep -E '^v?[0-9]+(\.[0-9]+)*$' | sort -uV | tail -n 1)
      if [[ $tagrev != "$rev" ]]; then
        status="pinned to $ref, but the lock differs from the tag (tag ${tagrev:0:12})"
      elif [[ -n $latest && $latest != "$ref" ]]; then
        status="pinned to $ref; newer release $latest"
      else
        status="pinned to $ref (latest release)"
      fi
      printf '%-20s %s  %s\n' "$name" "$locked" "$status"
      continue
    fi

    # Branch (or the default branch when flake.nix names none).
    if [[ $ref == - ]]; then
      head=$(git ls-remote "$url" HEAD | awk 'NR == 1 { print $1 }')
    else
      head=$(git ls-remote "$url" "refs/heads/$ref" | awk 'NR == 1 { print $1 }')
    fi
    if [[ -z $head ]]; then
      status="upstream lookup failed"
    elif [[ $head == "$rev" ]]; then
      status=current
    else
      # Commit count needs the GitHub API; skip it quietly without gh.
      ahead=$(gh api "repos/$repo/compare/$rev...$head" --jq .ahead_by 2>/dev/null) || ahead=""
      [[ $ahead == 1 ]] && s="" || s=s
      status="behind${ahead:+ by $ahead commit$s} (upstream ${head:0:12})"
    fi
    [[ $ref != - ]] && status="$status [$ref]"
    printf '%-20s %s  %s\n' "$name" "$locked" "$status"
  done
  exit
fi

# One "source pname" line per top-level package. pname falls back to
# parseDrvName for derivations that only set `name`.
#
# Packages that a bare NixOS / bare Home Manager config would also install
# (coreutils, less, man-db, ...) are subtracted: they come with the
# platform rather than from a choice made in this repo. The bare configs
# are evaluated against this flake's own inputs, so the baseline tracks
# the same nixpkgs and home-manager revisions as the real config. The
# catch: something listed by hand that is also a default (curl, openssh)
# gets subtracted too.
#
# --impure is needed for builtins.getFlake on a local path and for getEnv
# (how the host name gets in); the empty nix-path silences home-manager's
# probe for a nonexistent <nixpkgs>.
# shellcheck disable=SC2016 # the ${...} below is Nix interpolation
toplevel=$(OLDE_HOST=$host nix eval --impure --raw --option nix-path '' --expr '
  let
    flake = builtins.getFlake (toString ./.);
    real = flake.nixosConfigurations.${builtins.getEnv "OLDE_HOST"};
    cfg = real.config;
    pname = p: p.pname or (builtins.parseDrvName (p.name or "")).name;

    bareOs = flake.inputs.nixpkgs.lib.nixosSystem {
      inherit (real.pkgs.stdenv.hostPlatform) system;
      modules = [{
        fileSystems."/" = { device = "none"; fsType = "tmpfs"; };
        boot.loader.grub.enable = false;
        system.stateVersion = cfg.system.stateVersion;
      }];
    };
    bareHome = flake.inputs.home-manager.lib.homeManagerConfiguration {
      inherit (real) pkgs;
      modules = [{
        home.username = "bare";
        home.homeDirectory = "/home/bare";
        home.stateVersion = cfg.system.stateVersion;
      }];
    };

    minus = base: pkgs:
      let names = map pname base;
      in builtins.filter (n: !(builtins.elem n names)) (map pname pkgs);
    tag = src: map (n: "${src} ${n}");
    users = builtins.attrNames cfg.home-manager.users;
  in builtins.concatStringsSep "\n" (
    tag "system" (minus bareOs.config.environment.systemPackages cfg.environment.systemPackages)
    ++ builtins.concatMap
      (u: tag "hm:${u}" (minus bareHome.config.home.packages cfg.home-manager.users.${u}.home.packages))
      users
  )
' 2>/dev/null) || { echo "flake evaluation failed; rerun the nix eval by hand to see why" >&2; exit 1; }

# nix-olde line shape:
#   repology NAME "LATEST" | nixpkgs {"V1", ...} {"attr1", ...}
# A line is kept if the repology name or any nixpkgs attribute (with a
# leading "_" stripped, as in _1password-gui) equals a top-level pname.
# Name matching is heuristic: a top-level package whose pname matches
# neither will be missed.
awk '
  # Register each pname under itself and with any wrapper suffix stripped
  # (zathura-with-plugins -> zathura), recording each source only once.
  function add(name, s) {
    if (index("," src[name] ",", "," s ",")) return
    src[name] = (src[name] ? src[name] "," : "") s
  }
  NR == FNR {
    add($2, $1)
    base = $2
    if (sub(/-(with-plugins|wrapped|unwrapped|wrapper)$/, "", base)) add(base, $1)
    next
  }
  /^repology / {
    hit = ($2 in src) ? $2 : ""
    if (!hit && match($0, /\{[^}]*\}[[:space:]]*$/)) {
      n = split(substr($0, RSTART + 1, RLENGTH - 2), attrs, /[",[:space:]]+/)
      for (i = 1; i <= n && !hit; i++) {
        a = attrs[i]; sub(/^_/, "", a)
        if (a in src) hit = a
      }
    }
    if (hit) printf "%-14s %s\n", "[" src[hit] "]", $0
  }
' <(printf '%s\n' "$toplevel") "${1:-/dev/stdin}"
