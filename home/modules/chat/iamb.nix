# home/modules/chat/iamb.nix
#
# iamb, a terminal Matrix client with Vim-style modal keys (trial from
# 2026-11-20, side by side with Fractal, fractal.nix). Both are just
# Matrix devices on the same account, so running both doesn't conflict.
#
# The account (registered 2026-11-20 on Unredacted) is the one profile
# below. iamb requires a `profiles` table (without one it refuses the file:
# "missing field `profiles`"); with a single profile it uses it without
# asking. The server name is unredacted.org, which delegates to
# matrix.unredacted.org via .well-known, so iamb finds the homeserver
# itself. The Matrix ID is public, so it can go in the repo, and nothing
# secret does: iamb asks for the password (or does SSO / OAuth in the
# browser) at first login and keeps the session
# under ~/.local/share/iamb, which survives reboots (/home isn't wiped).
# iamb can't register accounts; create one on the homeserver's website.
#
# Colours: no [settings.theme] on purpose. iamb's defaults are the
# terminal's 16 ANSI colours, and kitty takes those from Noctalia, so iamb
# follows the palette without a template of its own.
#
# Every setting: iamb(5), or https://iamb.chat/configure.html.
_: {
  programs.iamb = {
    enable = true;

    settings.profiles.unredacted.user_id = "@amphiboly:unredacted.org";

    settings.settings = {
      # Desktop notifications for messages that the server's push rules
      # count as notifying (set the rules from any client; iamb only
      # reads them at startup).
      notifications.enabled = true;

      # Inline image previews. The protocol is detected, so under kitty it
      # uses kitty's graphics protocol; nothing to set.
      image_preview = {};
    };
  };

  # The package's own iamb.desktop says Terminal=true. This one, with the
  # same id, shadows it and runs iamb in kitty directly, like yazi's in
  # xdg.nix.
  # %u stays, since iamb is the handler for matrix: URIs in that entry.
  xdg.desktopEntries.iamb = {
    name = "iamb";
    genericName = "Matrix Client";
    exec = "kitty -- iamb %u";
    terminal = false;
    icon = "iamb";
    categories = ["Network" "InstantMessaging" "Chat"];
    mimeType = ["x-scheme-handler/matrix"];
  };
}
