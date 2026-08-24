# modules/nixos/pipewire.nix
_: {
  security.rtkit.enable = true; # Required for high-priority audio threads
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
}
