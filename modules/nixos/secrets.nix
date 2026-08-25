# modules/nixos/secrets.nix
_: {
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops/age/keys.txt";
    secrets = {
      # System & Admin Keys
      "rik-password-hash" = {neededForUsers = true;};
      # The attribute name sets the output path (/run/secrets/<name>); `key`
      # only picks the YAML key. Naming this "w11-cifs-password" published it
      # at /run/secrets/w11-cifs-password while filesystems.nix mounts with
      # credentials=/run/secrets/w11-cifs-credentials, so every mount failed
      # with "error 2 ... opening credential file". Name == YAML key here, so
      # `key` is redundant.
      "w11-cifs-credentials" = {owner = "root";};
      "restic-vault-password" = {owner = "root";};
      "panix-smtp-password" = {owner = "root";};

      # User Email Keys (Declaratively owned by rik)
      "spectrum-smtp-password" = {owner = "rik";};
      "gmail-amphiboly-password" = {owner = "rik";};
      "gmail-amphibolybackup-password" = {owner = "rik";};
      "gmail-cornwall-password" = {owner = "rik";};
    };
  };
}
