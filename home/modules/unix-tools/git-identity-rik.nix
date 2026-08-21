# home/modules/unix-tools/git-identity-rik.nix
{...}: {
  programs.git.settings.user = {
    name = "Rik Kabel";
    email = "amphiboly@gmail.com";
  };
}
