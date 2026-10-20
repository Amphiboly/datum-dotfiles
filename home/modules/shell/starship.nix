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
# Segment colours: user/host #9A348E, directory #DA627D, git #FCA17D,
# time #33658A. Outside a git repo the git segment is empty, leaving a
# sliver of orange between the arrows -- a known quirk of this layout.
_: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = "[](#9A348E)$username[on ](bg:#9A348E fg:white)$hostname[](fg:#9A348E bg:#DA627D)$directory[](fg:#DA627D bg:#FCA17D)$git_branch$git_status[](fg:#FCA17D bg:#33658A)$time[](fg:#33658A) $character";
      username = {
        disabled = false;
        show_always = true;
        style_user = "bg:#9A348E fg:white";
        style_root = "bg:#9A348E fg:red bold";
        format = "[ $user ]($style)";
      };
      hostname = {
        ssh_only = false;
        trim_at = ".";
        disabled = false;
        style = "bg:#9A348E fg:white";
        format = "[$hostname ]($style)";
      };
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bg:#DA627D fg:white bold";
        format = "[ $path ]($style)";
      };
      git_branch = {
        symbol = "🌱 ";
        style = "bg:#FCA17D fg:black";
        format = "[ $symbol$branch ]($style)";
      };
      git_status = {
        style = "bg:#FCA17D fg:black bold";
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
        style = "bg:#33658A fg:white";
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
}
