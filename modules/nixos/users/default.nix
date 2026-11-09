# modules/nixos/users/default.nix
#
# Cross-cutting user-management settings, not specific to any one account.
_: {
  # Structural requirement: Generates system-wide /etc/zshrc global paths
  # This resolves the PATH assertion failure for users using Zsh
  programs.zsh.enable = true;

  # Immutable since 2026-11-09: /etc/passwd, /etc/shadow and /etc/group are
  # rewritten from users.users at every activation (every switch and every
  # boot), passwords included. Passwords are admin-managed: rik's and
  # root's come from sops hashes (rik.nix, root.nix), guest's is a fixed
  # known one (guest.nix).
  #
  # Why not mutable: the impermanence plan (IMPERMANENCE-PLAN.md) wipes /
  # at boot, and /etc/shadow can't be carried across. pam_unix (what
  # `passwd` uses) and shadow-utils both replace it with rename(), which
  # fails on a bind mount and silently replaces a symlink, so a `passwd`
  # change would be lost at the next boot. Mutable users also let the live
  # password drift from the sops copy, which a reinstall then brought back.
  # Home Manager config is unaffected: users still apply their own without
  # a rebuild (the multi-user rule in CLAUDE.md).
  #
  # `passwd` still appears to work, but only until the next activation.
  # Don't use it. To change rik's password (root: the same with
  # root-password-hash):
  #  1. Hash the new password and store it:
  #       hash=$(mkpasswd -m yescrypt)
  #       SOPS_AGE_KEY_FILE=<(sudo cat /var/lib/sops/age/keys.txt) \
  #         nix shell nixpkgs#sops -c \
  #         sops set secrets.yaml '["rik-password-hash"]' "\"$hash\""
  #     then commit secrets.yaml.
  #  2. `nh os switch .`. The new password is live everywhere a password
  #     is asked for (greeter, lock screen, sudo).
  # Unaffected: the LUKS passphrase and the TPM PIN (disko-config.nix),
  # Gaze, and the GNOME login keyring, whose password is blank on purpose
  # (facial-auth.nix). Until 2026-11-09 this file had `passwd` re-encrypt
  # that keyring with the new password (pam_gnome_keyring on the passwd
  # stack), which would have undone the blank password; it's gone.
  #
  # NixOS refuses to build if neither root nor any wheel user has a
  # password, so this can't lock everyone out by accident.
  users.mutableUsers = false;
}
