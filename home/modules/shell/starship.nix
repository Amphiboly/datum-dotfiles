# home/modules/shell/starship.nix
{...}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = "$git_branch $git_status $directory $character";
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold cyan";
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
