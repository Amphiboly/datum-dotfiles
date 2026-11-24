# hosts/datum/secrets.nix
#
# Secrets only datum uses, from secrets/datum.yaml. The shared ones, and
# the sops settings themselves, are in modules/nixos/secrets.nix.
_: let
  sopsFile = ../../secrets/datum.yaml;
in {
  sops.secrets = {
    # datum's own login passwords (users/rik.nix, users/root.nix). Needed
    # before the users exist, so sops-nix decrypts them earlier.
    "rik-password-hash" = {
      inherit sopsFile;
      neededForUsers = true;
    };
    "root-password-hash" = {
      inherit sopsFile;
      neededForUsers = true;
    };

    # Private half of the key remote-builder.nix uses to reach nostrum.
    # Root-owned because the nix-daemon (root) opens the SSH connection.
    "nostrum-builder-ssh-key" = {
      inherit sopsFile;
      owner = "root";
    };

    # Syncthing identity (1Password "Syncthing - datum"). The device ID is
    # derived from the cert, so pinning it keeps datum's ID across a
    # reinstall. Wired into Home Manager in ./default.nix.
    "syncthing-datum-cert" = {
      inherit sopsFile;
      owner = "rik";
    };
    "syncthing-datum-key" = {
      inherit sopsFile;
      owner = "rik";
    };
  };
}
