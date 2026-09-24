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
# each github input's locked rev is compared with upstream's.
#
# Must run from the repo root (it evaluates the flake in `.`). HOST_ATTR
# selects a nixosConfigurations entry other than datum.
#
# Needs: bash, nix, awk and GNU date; --inputs also needs git. nix-olde
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
  # shellcheck disable=SC2016 # the ${...} below is Nix interpolation
  nix eval --impure --raw --expr '
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
      line = name: node: let l = lock.nodes.${node}.locked; in
        "${name} ${l.type} ${l.owner or "-"}/${l.repo or "-"} "
        + "${l.ref or "HEAD"} ${l.rev or "-"} ${toString l.lastModified}";
    in builtins.concatStringsSep ""
      (map (s: s + "\n")
        (builtins.attrValues (builtins.mapAttrs line lock.nodes.root.inputs)))
  ' | while read -r name type repo ref rev modified; do
    locked=$(date -u -d "@$modified" +%F)
    if [[ $type != github ]]; then
      printf '%-20s %s  skipped (%s input)\n' "$name" "$locked" "$type"
      continue
    fi
    head=$(git ls-remote "https://github.com/$repo" "$ref" | awk 'NR == 1 { print $1 }')
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
