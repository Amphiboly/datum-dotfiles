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
#
# Keys: vi-style, from upstream's vim_style_key_config.ron (v0.28.1). Help
# moves to F1, since h is now "left". Unlisted actions keep gitui's defaults
# (src/keys/key_list.rs). Home Manager writes this to key_bindings.ron,
# the name gitui reads (its option text still says key_config.ron).
{config, ...}: {
  programs.gitui = {
    enable = true;
    keyConfig = ''
      (
          open_help: Some(( code: F(1), modifiers: "")),

          move_left: Some(( code: Char('h'), modifiers: "")),
          move_right: Some(( code: Char('l'), modifiers: "")),
          move_up: Some(( code: Char('k'), modifiers: "")),
          move_down: Some(( code: Char('j'), modifiers: "")),

          popup_up: Some(( code: Char('p'), modifiers: "CONTROL")),
          popup_down: Some(( code: Char('n'), modifiers: "CONTROL")),
          page_up: Some(( code: Char('b'), modifiers: "CONTROL")),
          page_down: Some(( code: Char('f'), modifiers: "CONTROL")),
          home: Some(( code: Char('g'), modifiers: "")),
          end: Some(( code: Char('G'), modifiers: "SHIFT")),
          shift_up: Some(( code: Char('K'), modifiers: "SHIFT")),
          shift_down: Some(( code: Char('J'), modifiers: "SHIFT")),

          edit_file: Some(( code: Char('I'), modifiers: "SHIFT")),

          status_reset_item: Some(( code: Char('U'), modifiers: "SHIFT")),

          diff_reset_lines: Some(( code: Char('u'), modifiers: "")),
          diff_stage_lines: Some(( code: Char('s'), modifiers: "")),

          stashing_save: Some(( code: Char('w'), modifiers: "")),
          stashing_toggle_index: Some(( code: Char('m'), modifiers: "")),

          stash_open: Some(( code: Char('l'), modifiers: "")),

          abort_merge: Some(( code: Char('M'), modifiers: "SHIFT")),
      )
    '';
    theme = ''
      (
          syntax: Some("noctalia"),
      )
    '';
  };

  xdg.configFile."gitui/noctalia.tmTheme".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/bat/themes/noctalia.tmTheme";
}
