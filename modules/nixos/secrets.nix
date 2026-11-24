# modules/nixos/secrets.nix
#
# Secrets every host uses. They live in secrets/common.yaml, the default
# sopsFile. Host-only secrets go in hosts/<host>/secrets.nix, each with
# its own `sopsFile = ../../secrets/<host>.yaml`. Recipients per file are
# in .sops.yaml.
_: {
  sops = {
    defaultSopsFile = ../../secrets/common.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops/age/keys.txt";
    # No ssh host keys as decryption keys. With openssh enabled, sops-nix
    # defaults these to the ed25519 (age) and RSA (gnupg) host keys, but
    # .sops.yaml has only the admin age key above as a recipient, so the
    # host keys can't decrypt anything here. Clearing them leaves keyFile
    # as the only key sops needs at activation, which matters for the
    # impermanence plan (IMPERMANENCE-PLAN.md): the host keys can then be
    # restored later in boot, like any other state.
    age.sshKeyPaths = [];
    gnupg.sshKeyPaths = [];
    # Every host also declares rik-password-hash and root-password-hash in
    # its own file (users/rik.nix and users/root.nix read them): each
    # host has its own passwords.
    secrets = {
      # The attribute name sets the output path (/run/secrets/<name>); `key`
      # only picks the YAML key. Naming this "w11-cifs-password" published it
      # at /run/secrets/w11-cifs-password while filesystems.nix mounts with
      # credentials=/run/secrets/w11-cifs-credentials, so every mount failed
      # with "error 2 ... opening credential file". Name == YAML key here, so
      # `key` is redundant.
      "w11-cifs-credentials" = {owner = "root";};
      "restic-vault-password" = {owner = "root";};
      "panix-smtp-password" = {owner = "root";};
      # ntfy publish token (1Password); ntfy-alerts.nix sends it as Bearer.
      "ntfy-publish-token" = {owner = "root";};

      # User Email Keys (Declaratively owned by rik)
      "spectrum-smtp-password" = {owner = "rik";};
      "gmail-amphiboly-password" = {owner = "rik";};
      "gmail-amphibolybackup-password" = {owner = "rik";};
      "gmail-cornwall-password" = {owner = "rik";};
    };
  };
}
