# home/modules/media/mpv.nix
#
# mpv as the video player and default for video files, replacing
# cosmic-player (2026-10-29). The associations live here rather than in
# xdg.nix so they come and go with the player.
{lib, ...}: let
  # Every video/* type mpv's own desktop entry declares (mpv 0.41). Types
  # it doesn't list stay with whatever claims them.
  videoTypes = [
    "video/3gp"
    "video/3gpp"
    "video/3gpp2"
    "video/avi"
    "video/divx"
    "video/dv"
    "video/fli"
    "video/flv"
    "video/mkv"
    "video/mp2t"
    "video/mp4"
    "video/mp4v-es"
    "video/mpeg"
    "video/msvideo"
    "video/ogg"
    "video/quicktime"
    "video/vnd.avi"
    "video/vnd.divx"
    "video/vnd.mpegurl"
    "video/vnd.rn-realvideo"
    "video/webm"
    "video/x-avi"
    "video/x-flc"
    "video/x-flic"
    "video/x-flv"
    "video/x-m4v"
    "video/x-matroska"
    "video/x-mpeg2"
    "video/x-mpeg3"
    "video/x-ms-afs"
    "video/x-ms-asf"
    "video/x-ms-wmv"
    "video/x-ms-wmx"
    "video/x-ms-wvxvideo"
    "video/x-msvideo"
    "video/x-ogm"
    "video/x-ogm+ogg"
    "video/x-theora"
    "video/x-theora+ogg"
  ];
in {
  programs.mpv.enable = true;

  xdg.mimeApps.defaultApplications = lib.genAttrs videoTypes (_: ["mpv.desktop"]);
}
