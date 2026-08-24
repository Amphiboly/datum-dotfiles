# ~/Projects/datum-config/home.nix
{pkgs, ...}: {
  imports = [
    ./home/modules/theme/fonts.nix
    ./home/modules/theme/colors.nix
    ./home/modules/unix-tools/git.nix
    ./home/modules/unix-tools/git-identity-rik.nix
    ./home/modules/unix-tools/cli-utils.nix
    ./home/modules/unix-tools/claude-code.nix
    ./home/modules/unix-tools/claude-code-rik.nix
    ./home/modules/shell/zsh.nix
    ./home/modules/shell/zsh-rik.nix
    ./home/modules/shell/starship.nix
    ./home/modules/shell/fzf-zoxide.nix
    ./home/modules/terminal/kitty.nix
    ./home/modules/terminal/kitty-rik.nix
    ./home/modules/editors/helix.nix
    ./home/modules/editors/helix-rik.nix
    ./home/modules/editors/vim.nix
    ./home/modules/editors/vim-rik.nix
    ./home/modules/editors/zed.nix
    ./home/modules/editors/zed-rik.nix
    ./home/modules/browsers/firefox.nix
    ./home/modules/browsers/firefox-rik.nix
    ./home/modules/productivity/office.nix
    ./home/modules/productivity/thunderbird.nix
    ./home/modules/productivity/maestral-service.nix
    ./home/modules/desktop-integration/xdg.nix
    ./home/modules/desktop-integration/onepassword.nix
    ./home/modules/desktop-integration/compose-key.nix
    ./home/modules/desktop-integration/wallpapers.nix
  ];

  home = {
    username = "rik";
    homeDirectory = "/home/rik";
    stateVersion = "26.05";
  };

  # =========================================================================
  # Rik-specific one-off scripts (not a shared category, so it stays here)
  # =========================================================================
  home.packages = with pkgs; [
    (writeScriptBin "mksecrets" (builtins.readFile ./mksecrets.sh))
  ];

  # =========================================================================
  # NATIVE INFRASTRUCTURE DEPLOYMENT: REMMINA WITH COUPLING PLUGINS
  # =========================================================================
  services.remmina = {
    enable = true;
    addRdpMimeTypeAssoc = true;
  };
}
