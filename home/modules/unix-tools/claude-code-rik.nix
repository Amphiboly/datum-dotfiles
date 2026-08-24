# home/modules/unix-tools/claude-rik.nix
{pkgs, ...}: {
  home.file.".claude/settings.local.json".text = builtins.toJSON {
    mcpServers = {
      nixos = {
        # Nix correctly resolves the package path here even though
        # the package is installed in the sibling file.
        command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
        args = [];
      };
    };

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
