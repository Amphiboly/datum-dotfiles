# home/modules/shell/starship.nix
#
# Powerline-style prompt (after starship's "Pastel Powerline" preset):
# four coloured segments -- user@host, directory, git, time -- joined by
# powerline arrows, then the vim-mode character.
#
# How the colours work: a style only applies to text inside `[...](style)`,
# and each module renders its own text with its own `style`. So every
# module in a segment carries that segment's `bg:`, and its `format` keeps
# the padding spaces inside the brackets. Each arrow between segments is
# `fg:<previous bg> bg:<next bg>`. Modules also need an explicit `format`,
# because several defaults append words (username and hostname end in
# " in ").
#
# Segment colours are palette names, not hex: user/host `mauve`, directory
# `red`, git `flamingo`, time `blue`, segment text `base`. Outside a git
# repo the git segment is empty, leaving a sliver of it between the arrows
# -- a known quirk of this layout.
#
# The palette comes from Noctalia. Its built-in starship template renders
# [palettes.noctalia] into ~/.cache/noctalia/starship-palette.toml, and its
# hook splices that into the starship config, with `palette = "noctalia"`.
# Starship has no include, and the Home Manager config is a read-only store
# link, so the hook can't edit it. Instead STARSHIP_CONFIG points at a
# writable copy in $XDG_STATE_HOME: activation copies the generated config
# there and runs Noctalia's own hook on it once, and from then on Noctalia
# rewrites the palette block there on every palette change (the hook finds
# the path through the systemd user environment). Starship rereads its
# config at each prompt, so open shells follow along.
#
# [palettes.fallback] holds the original Pastel Powerline colours. It is
# the palette until Noctalia has rendered one (a fresh profile, or a session
# without Noctalia), and what ~/.config/starship.toml uses in shells started
# before STARSHIP_CONFIG was set.
{
  config,
  lib,
  pkgs,
  ...
}: let
  liveConfig = "${config.xdg.stateHome}/starship/starship.toml";
  noctaliaPalette = "${config.xdg.cacheHome}/noctalia/starship-palette.toml";
  noctaliaHook = "${config.programs.noctalia.package}/share/noctalia/assets/templates/starship/apply.sh";
in {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      palette = "fallback";
      palettes.fallback = {
        mauve = "#9A348E";
        red = "#DA627D";
        flamingo = "#FCA17D";
        blue = "#33658A";
        base = "#FFFFFF";
      };
      format = "[](mauve)$username[on ](bg:mauve fg:base)$hostname[](fg:mauve bg:red)$directory[](fg:red bg:flamingo)$git_branch$git_status[](fg:flamingo bg:blue)$time[](fg:blue) $character";
      username = {
        disabled = false;
        show_always = true;
        style_user = "bg:mauve fg:base";
        style_root = "bg:mauve fg:base bold underline";
        format = "[ $user ]($style)";
      };
      hostname = {
        ssh_only = false;
        trim_at = ".";
        disabled = false;
        style = "bg:mauve fg:base";
        format = "[$hostname ]($style)";
      };
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bg:red fg:base bold";
        format = "[ $path ]($style)";
      };
      git_branch = {
        symbol = "🌱 ";
        style = "bg:flamingo fg:base";
        format = "[ $symbol$branch ]($style)";
      };
      git_status = {
        style = "bg:flamingo fg:base bold";
        conflicted = "🏳 ";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕";
        untracked = " +?";
        modified = " *~";
        staged = " +";
        renamed = " »";
        deleted = " -";
        format = "([$all_status$ahead_behind ]($style))";
      };
      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:blue fg:base";
        format = "[ $time ]($style)";
      };
      character = {
        success_symbol = "[ I ](bold green) ❯";
        error_symbol = "[ I ](bold red) ❯";
        vimcmd_symbol = "[ N ](bold yellow) ❯";
        vimcmd_replace_one_symbol = "[ R ](bold purple) ❯";
        vimcmd_replace_symbol = "[ R ](bold purple) ❯";
        vimcmd_visual_symbol = "[ V ](bold magenta) ❯";
      };
    };
  };

  # Shells read the first (mkForce: the starship module sets it to its own
  # configPath); Noctalia's hook, run by the noctalia user service, reads
  # the second via `systemctl --user show-environment`.
  home.sessionVariables.STARSHIP_CONFIG = lib.mkForce liveConfig;
  systemd.user.sessionVariables.STARSHIP_CONFIG = liveConfig;

  # After linkGeneration, so the generated starship.toml is in place. The
  # copy is overwritten on every activation (dropping the palette block),
  # and the hook puts the current palette straight back. A failed hook
  # warns rather than aborting activation; the fallback palette still works.
  home.activation.starshipLiveConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
    live=${lib.escapeShellArg liveConfig}
    run mkdir -p "$(dirname "$live")"
    run install -m 0644 ${config.home.file.${config.programs.starship.configPath}.source} "$live"
    if [[ -f ${lib.escapeShellArg noctaliaPalette} ]]; then
      run env PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gawk pkgs.gnused pkgs.gnugrep pkgs.diffutils]} \
        STARSHIP_CONFIG="$live" ${pkgs.bash}/bin/bash ${noctaliaHook} \
        || warnEcho "Noctalia's starship hook failed; prompt keeps the fallback palette"
    fi
  '';
}
