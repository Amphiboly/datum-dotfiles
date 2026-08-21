# home/modules/desktop-integration/compose-key.nix
#
# Two halves of the same feature: COSMIC's input config binds Right Alt as
# the Compose trigger, and .XCompose defines what it produces.
{...}: {
  home.file.".config/cosmic/com.system76.CosmicInput/v1/keys".text = ''
    (
        caps_lock: None,
        num_lock: true,
        scroll_lock: false,
        xkb_options: Some("compose:ralt"),
    )
  '';

  home.file.".XCompose".source = ../../../assets/xcompose-vim;
}
