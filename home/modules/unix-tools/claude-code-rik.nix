# home/modules/unix-tools/claude-rik.nix
#
# NOTE: MCP servers cannot be declared here. Claude Code settings files have
# no mcpServers key, so a block placed here is read as valid JSON, silently
# ignored, and `claude mcp list` stays empty -- while the permissions below,
# in the same file, apply normally. Server definitions belong in
# ~/.claude.json (user scope) or <repo>/.mcp.json (project scope); mcp-nixos
# is wired up in the checked-in .mcp.json at the repo root.
_: {
  home.file.".claude/settings.local.json".text = builtins.toJSON {
    permissions = {
      allow = [
        "Read(//home/rik/Projects/datum/datum-config/**)"
        "Read(//nix/store/**)"
        "WebSearch"
        "Bash(v4l2-ctl --list-devices)"
        "Bash(lsusb)"
        "Bash(nix search *)"
        "Bash(v4l2-ctl -d /dev/video0 --list-formats-ext)"
        "Read(//etc/modprobe.d/**)"
        "Bash(nix eval *)"
        "Bash(nix build *)"
        "Bash(journalctl --list-boots)"
        "Bash(journalctl -b all -k)"
        "Bash(journalctl -b all -k -o short-iso)"
        "Bash(uniq -f1 -c)"
        "Bash(awk '{print $1, $NF, $\\(NF-2\\), $\\(NF-1\\)}')"
        "Bash(uniq -f1)"
      ];
    };
  };
}
