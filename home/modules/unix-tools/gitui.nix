# home/modules/unix-tools/gitui.nix
#
# gitui (github:gitui-org/gitui): a terminal UI for git -- stage files,
# hunks or single lines, commit/amend (hooks run), stash, branches,
# push/fetch, searchable log, submodules. Alongside plain git, not instead
# of it: no interactive rebase, no branch graph in the log, no git-lfs or
# sparse repos (README "Known Limitations"). https remotes need an explicit
# credential.helper; ssh goes through SSH_AUTH_SOCK, here 1Password's agent.
#
# Colours: gitui's default theme uses named terminal colours, so it already
# follows kitty's palette, i.e. Noctalia's. Diff syntax highlighting uses a
# TextMate theme from gitui's config dir; this links in the one Noctalia's
# bat template keeps rendering (out-of-store, so it follows palette
# changes; gitui reads it at startup).
{config, ...}: {
  programs.gitui = {
    enable = true;
    theme = ''
      (
          syntax: Some("noctalia"),
      )
    '';
  };

  xdg.configFile."gitui/noctalia.tmTheme".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/bat/themes/noctalia.tmTheme";
}
