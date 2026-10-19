# home/modules/productivity/maestral-service.nix
#
# Opt-in per-user Dropbox sync. The `maestral` binary is installed system-wide
# (see modules/nixos/dropbox-sync.nix); this module only wires up this user's
# own sync daemon against their own Dropbox account. Profiles that shouldn't
# get a Dropbox sync (e.g. guest) simply don't import this module.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.productivity.maestral;

  # Maestral keeps its selective-sync list in its own state
  # (~/.config/maestral), which Nix doesn't manage, so a relink or a fresh
  # home silently drops it. Re-asserting the list before every start puts it
  # back before the daemon can sync anything. `excluded add` is idempotent
  # and accepts paths that don't exist (yet), so this is safe to repeat. If
  # it fails, the daemon does not start: no sync is better than an
  # unfiltered one.
  #
  # Limitation: this only guards starts made through this unit. When linking
  # an account from scratch, run `maestral auth link` first and then start
  # the service; an interactive `maestral start` on an unlinked setup runs
  # its own first-sync wizard and never passes through this check.
  ensureExcluded = pkgs.writeShellScript "maestral-ensure-excluded" ''
    exec ${pkgs.maestral}/bin/maestral excluded add ${lib.escapeShellArgs cfg.excludedPaths}
  '';
in {
  options.productivity.maestral = {
    excludedPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["/Apps/Some Big Archive"];
      description = ''
        Dropbox paths (relative to the Dropbox root, leading slash) that are
        never synced to this machine. Re-added before each daemon start.
      '';
    };
  };

  config.systemd.user.services.maestral = {
    Unit = {Description = "Maestral Dropbox Synchronization Daemon";};
    Install = {WantedBy = ["graphical-session.target"];};
    Service = {
      ExecStartPre = lib.mkIf (cfg.excludedPaths != []) "${ensureExcluded}";
      ExecStart = "${pkgs.maestral}/bin/maestral start -f";
      ExecStop = "${pkgs.maestral}/bin/maestral stop";
      Restart = "on-failure";
      # Spaced out so a failing pre-start (e.g. offline at login) keeps
      # retrying instead of tripping systemd's start rate limit.
      RestartSec = 30;
      Nice = 10;
    };
  };
}
