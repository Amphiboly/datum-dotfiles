# home/modules/productivity/thunderbird.nix
#
# Accounts are managed imperatively for now: multiple days spent trying to get
# SMTP + NNTP + RSS all declared at once never worked — one or two of the
# three would come up, never all three. Only the package/binary is managed
# declaratively; the commented block below is kept as reference for a future
# attempt.
{config, ...}: {
  programs.thunderbird.enable = true;

  # =========================================================================
  # The following is disabled after the initial build so that home-manager
  # does not rebuild the accounts, losing non-smtp accounts in the process.
  # NOTE: The password entries are untested.
  # 1. CLEAN THUNDERBIRD MAIN SYSTEM BLOCK FOR REFERENCE
  # =========================================================================
  # programs.thunderbird = {
  #   enable = true;
  #   profiles.default = {
  #     isDefault = true;
  #     feedAccounts = {};
  #     settings = {
  #       "mail.accountmanager.rememberpasswords" = true;
  #       "mail.root.none" = true;
  #     };
  #   };
  # };
  #
  # -------------------------------------------------------------------------
  # THE THUNDERBIRD EMAIL ACCOUNTS FOR REFERENCE
  # -------------------------------------------------------------------------
  # accounts.email.accounts = {
  #   "Panix Mail" = {
  #     primary = true;
  #     realName = "Rik Kabel";
  #     address = "rik@panix.com";
  #     userName = "rik@panix.com";
  #     flavor = "plain";
  #     imap = {
  #       host = "mail.panix.com";
  #       port = 143;
  #       tls = {
  #         enable = true;
  #         useStartTls = true;
  #       };
  #     };
  #     smtp = {
  #       host = "mail.panix.com";
  #       port = 587;
  #       tls = {
  #         enable = true;
  #         useStartTls = true;
  #       };
  #     };
  #     thunderbird = {
  #       enable = true;
  #       profiles = ["default"];
  #     };
  #     passwordFile = config.sops.secrets."panix-smtp-password".path;
  #   };

  #   "Spectrum Mail" = {
  #     realName = "Richard Kabel";
  #     address = "kabel5cd@charter.net";
  #     userName = "kabel5cd@charter.net";
  #     flavor = "plain";
  #     imap = {
  #       host = "mobile.charter.net";
  #       port = 993;
  #       tls = {
  #         enable = true;
  #         useStartTls = false;
  #       };
  #     };
  #     smtp = {
  #       host = "mobile.charter.net";
  #       port = 587;
  #       tls = {
  #         enable = true;
  #         useStartTls = true;
  #       };
  #     };
  #     thunderbird = {
  #       enable = true;
  #       profiles = ["default"];
  #     };
  #     passwordFile = config.sops.secrets."spectrum-smtp-password".path;
  #   };

  #   "Amphiboly Gmail" = {
  #     realName = "Rik Kabel";
  #     address = "amphiboly@gmail.com";
  #     userName = "amphiboly@gmail.com";
  #     flavor = "gmail.com";
  #     thunderbird = {
  #       enable = true;
  #       profiles = ["default"];
  #       settings = id: {
  #         "mail.server.server_${id}.authMethod" = 10;
  #         "mail.smtpserver.smtp_${id}.authMethod" = 10;
  #       };
  #     };
  #     passwordFile = config.sops.secrets."gmail-amphiboly-password".path;
  #   };

  #   "Amphiboly Backup Gmail" = {
  #     realName = "Rik Kabel";
  #     address = "amphiboly.backup@gmail.com";
  #     userName = "amphiboly.backup@gmail.com";
  #     flavor = "gmail.com";
  #     thunderbird = {
  #       enable = true;
  #       profiles = ["default"];
  #       settings = id: {
  #         "mail.server.server_${id}.authMethod" = 10;
  #         "mail.smtpserver.smtp_${id}.authMethod" = 10;
  #       };
  #     };
  #     passwordFile = config.sops.secrets."gmail-amphibolybackup-password".path;
  #   };

  #   "Cornwall HOA Gmail" = {
  #     realName = "Cornwall Association";
  #     address = "Cornwall.HOA@gmail.com";
  #     userName = "Cornwall.HOA@gmail.com";
  #     flavor = "gmail.com";
  #     thunderbird = {
  #       enable = true;
  #       profiles = ["default"];
  #       settings = id: {
  #         "mail.server.server_${id}.authMethod" = 10;
  #         "mail.smtpserver.smtp_${id}.authMethod" = 10;
  #       };
  #     };
  #     passwordFile = config.sops.secrets."gmail-cornwall-password".path;
  #   };
  # };
}
