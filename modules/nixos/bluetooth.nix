# ~/Projects/datum-config/bluetooth.nix
_: {
  # 1. CORE HARDWARE BLUETOOTH DAEMON ENGINES
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Automatically powers up the chip so devices pair immediately
    settings = {
      General = {
        # Enables modern Bluetooth features like battery level reporting in your top bar
        Experimental = true;
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  # Enable the background systemd service for bluetooth management utilities
  services.blueman.enable = true;

  # 2. PIPEWIRE AUDIO CODEC PLATFORM OVERRIDES
  services.pipewire.wireplumber.extraConfig = {
    "10-bluetooth-policy" = {
      "wireplumber.profiles" = {
        # Forces WirePlumber to prioritize high-fidelity stereo media playback (A2DP)
        # over low-quality bidirectional headset profiles automatically
        "bluez5.a2dp.profile" = "a2dp-sink";
      };
    };

    "11-bluetooth-codecs" = {
      "monitor.bluez.properties" = {
        # Enables the complete modern suite of high-performance wireless audio formats
        "bluez5.codecs" = ["ldac" "aptx_hd" "aptx" "aac" "sbc_xq"];

        # Enables hardware volume synchronization between your laptop and your headphones
        "bluez5.enable-hw-volume" = true;
      };
    };
  };
}
