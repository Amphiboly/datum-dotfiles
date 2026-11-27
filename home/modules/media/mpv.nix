# home/modules/media/mpv.nix
#
# mpv as the video player and default for video files, replacing
# cosmic-player (2026-10-29), and since 2026-11-22 the music player too,
# replacing cmus. The associations live here rather than in xdg.nix so
# they come and go with the player.
#
# Why cmus went: it was the only thing on datum pulling in ffmpeg 7
# (nixpkgs pins cmus there, cmus/cmus#1459), which carries about 40 CVEs
# fixed only in the newer series (vulnix, 2026-11-22). mpv uses the
# current ffmpeg. The library is folders under ~/Dropbox/Music, opened
# from Luciole or yazi.
{
  lib,
  pkgs,
  ...
}: let
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

  # Every audio/* type mpv's desktop entry declares (mpv 0.42). mpv was
  # already the only claimant for these; listing them keeps it the
  # default if something else that claims audio gets installed.
  audioTypes = [
    "audio/3gpp"
    "audio/3gpp2"
    "audio/aac"
    "audio/ac3"
    "audio/aiff"
    "audio/AMR"
    "audio/amr-wb"
    "audio/dv"
    "audio/eac3"
    "audio/flac"
    "audio/m3u"
    "audio/m4a"
    "audio/mp1"
    "audio/mp2"
    "audio/mp3"
    "audio/mp4"
    "audio/mpeg"
    "audio/mpeg2"
    "audio/mpeg3"
    "audio/mpegurl"
    "audio/mpg"
    "audio/musepack"
    "audio/ogg"
    "audio/opus"
    "audio/rn-mpeg"
    "audio/scpls"
    "audio/vnd.dolby.heaac.1"
    "audio/vnd.dolby.heaac.2"
    "audio/vnd.dts"
    "audio/vnd.dts.hd"
    "audio/vnd.rn-realaudio"
    "audio/vnd.wave"
    "audio/vorbis"
    "audio/wav"
    "audio/webm"
    "audio/x-aac"
    "audio/x-adpcm"
    "audio/x-aiff"
    "audio/x-ape"
    "audio/x-m4a"
    "audio/x-matroska"
    "audio/x-mp1"
    "audio/x-mp2"
    "audio/x-mp3"
    "audio/x-mpegurl"
    "audio/x-mpg"
    "audio/x-ms-asf"
    "audio/x-ms-wma"
    "audio/x-musepack"
    "audio/x-pls"
    "audio/x-pn-au"
    "audio/x-pn-realaudio"
    "audio/x-pn-wav"
    "audio/x-pn-windows-pcm"
    "audio/x-realaudio"
    "audio/x-scpls"
    "audio/x-shorten"
    "audio/x-tta"
    "audio/x-vorbis"
    "audio/x-vorbis+ogg"
    "audio/x-wav"
    "audio/x-wavpack"
  ];
in {
  programs.mpv = {
    enable = true;
    # Opening one file also queues the others of the same kind in its
    # folder: a track plays on through the album, an episode on to the
    # next. Without it mpv plays just the file it was given.
    config.autocreate-playlist = "same";

    # MPRIS, so the Noctalia media widget (and anything else on the
    # session bus) sees what mpv plays and can pause/skip it. mpv has no
    # MPRIS of its own. Home Manager loads scripts by wrapping the mpv
    # binary with --script=..., not through mpv.conf, so this also covers
    # the mpv that tera (tera.nix) starts. For a radio stream the title is
    # the stream's ICY "Artist - Song" when the station sends it; there's
    # no art. Pausing from the widget pauses mpv behind tera's back, so
    # tera's own display can disagree until you act in it. Added
    # 2026-11-27.
    scripts = [pkgs.mpvScripts.mpris];
  };

  xdg.mimeApps.defaultApplications = lib.genAttrs (videoTypes ++ audioTypes) (_: ["mpv.desktop"]);
}
