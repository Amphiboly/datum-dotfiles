{
  config,
  lib,
  pkgs,
  ...
}: {
  # 1. Fastfetch configuration
  environment.etc = {
    "fastfetch/config.jsonc".text = ''
      {
          "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
          "logo": {
              "padding": {
                  "top": 3
              }
          },
          "modules": [
              "break",
              {
                  "type": "os",
                  "key": "┌",
                  "keyColor": "cyan",
                  "format": "{3}"
              },
              {
                  "type": "kernel",
                  "key": "├",
                  "keyColor": "yellow"
              },
              {
                  "type": "packages",
                  "key": "├󰏖",
                  "keyColor": "yellow"
              },
              {
                  "type": "shell",
                  "key": "└",
                  "keyColor": "yellow"
              },
              {
                  "type": "custom",
                  "key": "┌",
                  "format": "Noctalia",
                  "keyColor": "blue"
              },
              {
                  "type": "wm",
                  "key": "├",
                  "keyColor": "blue"
              },
              {
                  "type": "lm",
                  "key": "├󰧨",
                  "keyColor": "blue"
              },
              {
                  "type": "icons",
                  "key": "├󰀻",
                  "keyColor": "blue"
              },
              {
                  "type": "terminal",
                  "key": "├",
                  "keyColor": "blue"
              },
              {
                  "type": "custom",
                  "format": "helix",
                  "key": "├",
              },
              {
                  "type": "colors",
                  "key": "└ ",
                  "symbol": "circle"
              },
              {
                  "type": "host",
                  "key": "┌󰌢",
                  "keyColor": "green"
              },
              {
                  "type": "cpu",
                  "format": "{name} ({cores-physical}C/{cores-logical}T) @ {freq-base}/{freq-max} {temperature}",
                  "temp": true,
      	    "key": "├󰻠",
                  "keyColor": "green"
              },
              {
                  "type": "gpu",
                  "format": "{name} {temperature}",
                  "temp": true,
                  "key": "├󰍛",
                  "keyColor": "green"
              },
              {
                  "type": "disk",
                  "key": "├",
                  "keyColor": "green"
              },
              {
                  "type": "memory",
                  "key": "├󰑭",
                  "keyColor": "green"
              },
              {
                  "type": "swap",
                  "key": "├󰓡",
                  "keyColor": "green"
              },
              {
                  "type": "display",
                  "key": "├󰍹",
                  "keyColor": "green"
              },
              {
                  "type": "battery",
                  "key": "└\uf244",
                  "keyColor": "green",
                  "temp": true, // Adds temperature block safely to the side
                  "format": "{capacity} [{status}]" // Explicit text flags avoid index shifting issues
              }
          ]
      }
    '';
  };
}
