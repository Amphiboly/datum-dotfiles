# home/modules/unix-tools/git-identity-rik.nix
_: {
  programs.git.settings.user = {
    name = "Rik Kabel";
    email = "amphiboly@gmail.com";
  };
}
