# home/modules/unix-tools/git.nix
#
# Generic mechanism only — no identity here. See git-identity-rik.nix for
# the per-user name/email, imported only by profiles that want it.
_: {
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        lg = "log --oneline --graph --decorate";
      };
    };
  };
}
