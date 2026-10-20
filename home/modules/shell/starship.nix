# home/modules/shell/starship.nix
_: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      #     format = "$git_branch $git_status $directory $character";
      format = "[ ](#9A348E) $username on $hostname [ ](bg:#DA627D fg:#9A348E) $directory [ ](fg:#DA627D bg:#FCA17D) $git_branch $git_status [ ](fg:#06969A bg:#33658A) $time [ ](fg:#33658A) ";
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold cyan";
      };
      hostname = {
        ssh_only = false;
        trim_at = ".";
        disabled = false;
      };
      username = {
        disabled = false;
        show_always = true;
        style_user = "white";
        style_root = "red bold";
      };
      git_branch = {
        symbol = "🌱 ";
        style = "bold magenta";
        format = "on [$symbol$branch]($style) ";
      };
      git_status = {
        style = "bold red";
        conflicted = "🏳 ";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕";
        untracked = " +?";
        modified = " *~";
        staged = " +";
        renamed = " »";
        deleted = " -";
        format = "([$all_status$ahead_behind]($style) )";
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
