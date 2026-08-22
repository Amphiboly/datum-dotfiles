# home/modules/productivity/maestral-service.nix
#
# Opt-in per-user Dropbox sync. The `maestral` binary is installed system-wide
# (see modules/nixos/dropbox-sync.nix); this module only wires up this user's
# own sync daemon against their own Dropbox account. Profiles that shouldn't
# get a Dropbox sync (e.g. guest) simply don't import this module.
{pkgs, ...}: {
  systemd.user.services.maestral = {
    Unit = {Description = "Maestral Dropbox Synchronization Daemon";};
    Install = {WantedBy = ["graphical-session.target"];};
    Service = {
      ExecStart = "${pkgs.maestral}/bin/maestral start -f";
      ExecStop = "${pkgs.maestral}/bin/maestral stop";
      Restart = "on-failure";
      Nice = 10;
    };
  };
}
