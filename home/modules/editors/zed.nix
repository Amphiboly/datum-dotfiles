# home/modules/editors/zed.nix
#
# Enablement only: extensions, LSP/formatter wiring, privacy defaults, and
# the CLI shim. See zed-rik.nix for theme/fonts and the $VISUAL default.
{pkgs, ...}: {
  # Permanent user binary link so 'spawn,zed' works natively
  home.packages = [
    (pkgs.runCommand "zed-cli-link" {} "mkdir -p $out/bin && ln -s ${pkgs.zed-editor}/bin/zeditor $out/bin/zed")
  ];

  programs.zed-editor = {
    enable = true;

    # 1. Declarative Extension Pre-install Array Set
    extensions = [
      "nix" # Official Nix expression syntax highlighter and formatter tracking
      "typst" # Native Tinymist language compiler environment link
    ];

    userSettings = {
      # Smooth modern desktop UI interface behaviors
      telemetry = {
        metrics = false;
        crash_reporting = false;
      };

      # Language Specific Workspace Formatter Pipelines
      languages = {
        Nix = {
          language_servers = ["nixd"];
          format_on_save = "on";
        };
        Typst = {
          language_servers = ["tinymist"];
          format_on_save = "on";
        };
      };
    };
  };
}
