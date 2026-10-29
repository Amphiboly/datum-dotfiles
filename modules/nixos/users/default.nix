# modules/nixos/users/default.nix
#
# Cross-cutting user-management settings, not specific to any one account.
{lib, ...}: {
  # Structural requirement: Generates system-wide /etc/zshrc global paths
  # This resolves the PATH assertion failure for users using Zsh
  programs.zsh.enable = true;

  # Mutable on purpose: users change their own passwords with `passwd`,
  # without a rebuild (the multi-user rule in CLAUDE.md). The cost is that
  # declared passwords (initialPassword, hashedPasswordFile) only apply when
  # an account is created, never again. See rik.nix for how that bit.
  #
  # Changing rik's login password (guest: the same, without the sops step,
  # since guest.nix declares none):
  #  1. `passwd`, as rik. Live at once, everywhere a password is asked for
  #     (greeter, lock screens, sudo); no rebuild.
  #  2. Keep the sops copy in step, or a reinstall brings back the old
  #     password. Hash the NEW password and store it:
  #       hash=$(mkpasswd -m yescrypt)
  #       SOPS_AGE_KEY_FILE=<(sudo cat /var/lib/sops/age/keys.txt) \
  #         nix shell nixpkgs#sops -c \
  #         sops set secrets.yaml '["rik-password-hash"]' "\"$hash\""
  #     then commit secrets.yaml. A rebuild changes nothing on the running
  #     system: the hash is read only when an account is created.
  #  3. Nothing to do for the GNOME keyring: `passwd` re-encrypts
  #     login.keyring with the new password itself (enableGnomeKeyring
  #     below). That needs the keyring daemon running, so run `passwd` in
  #     a desktop session. From a console or over ssh the keyring keeps
  #     the old password; then fix it with `nix run nixpkgs#seahorse`
  #     (Passwords > Login > Change Password).
  # Unaffected: the LUKS passphrase and the TPM PIN (disko-config.nix),
  # and Gaze.
  #
  # Doing it the other way round also works: mkpasswd first, then
  # `sudo usermod -p "$hash" rik`, so one hash goes to both places.
  users.mutableUsers = true;

  # Without it, `passwd` changes the login password but leaves
  # login.keyring encrypted with the old one, and the next unlock at login
  # (/etc/pam.d/login carries pam_gnome_keyring) silently fails.
  #
  # Turning it on alone does nothing: nixpkgs orders the password rules
  # unix (sufficient) and then gnome_keyring, and `sufficient` ends the
  # stack as soon as the password change succeeds, so the keyring rule
  # never runs. As `required`, pam_unix still decides the outcome (the
  # keyring rule is only `optional`), but the stack goes on to the keyring
  # rule, which reuses the old and new passwords pam_unix collected
  # (use_authtok).
  security.pam.services.passwd = {
    enableGnomeKeyring = true;
    rules.password.unix.control = lib.mkForce "required";
  };
}
