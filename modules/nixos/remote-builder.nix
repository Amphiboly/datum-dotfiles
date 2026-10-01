# modules/nixos/remote-builder.nix
#
# Offload builds to nostrum (Fedora 44, Nix from Fedora's RPM), reached over
# Tailscale. datum's i7-7500U takes ages on anything uncached (e.g. noctalia,
# which builds from source now that its input follows our nixpkgs);
# nostrum's i7-1355U has 3x the threads and 4x the RAM.
#
# How the pieces fit:
# - The nix-daemon (root) opens the SSH connection, so it can't use rik's
#   1Password agent. It uses a dedicated passphrase-less key, kept in
#   secrets.yaml as `nostrum-builder-ssh-key` (see secrets.nix).
# - On nostrum the key sits in ~rik/.ssh/authorized_keys with
#   `restrict,command="/usr/bin/nix-daemon --stdio"`, so all it can do is
#   speak the Nix daemon protocol -- no shell, no forwarding. rik is in
#   nostrum's trusted-users, which ssh-ng needs to build and import paths.
# - publicHostKey pins nostrum's host key (base64 of
#   /etc/ssh/ssh_host_ed25519_key.pub), so root needs no known_hosts entry.
#
# When nostrum is unreachable (asleep on battery, datum off the tailnet), the
# connection fails after ConnectTimeout and Nix builds locally instead.
{config, ...}: {
  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "nostrum.taildad098.ts.net";
        protocol = "ssh-ng";
        sshUser = "rik";
        sshKey = config.sops.secrets."nostrum-builder-ssh-key".path;
        publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpTaDJWRklWMmhrRHhaeHlUczBCWG90MzFubkNQeUpsaERoL0NNWTdFcEU=";
        system = "x86_64-linux";
        # nostrum is the daily driver: cap concurrent jobs from datum so a
        # daytime build leaves it usable. Each job still gets all its cores.
        maxJobs = 4;
        speedFactor = 4;
        # /dev/kvm is present on nostrum, so NixOS VM tests can run there.
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
    ];
    # Let nostrum download dependencies from cache.nixos.org itself instead
    # of datum uploading them over the tailnet.
    settings.builders-use-substitutes = true;
  };

  # Fail over to local building quickly when nostrum is down. ssh's default
  # is the TCP timeout (minutes), which would stall every build in the
  # meantime.
  programs.ssh.extraConfig = ''
    Host nostrum.taildad098.ts.net
      ConnectTimeout 5
  '';
}
