# modules/nixos/secrets.nix
{...}: {
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops/age/keys.txt";
    secrets = {
      # System & Admin Keys
      "rik-password-hash" = {neededForUsers = true;};
      "w11-cifs-password" = {key = "w11-cifs-credentials";};
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
