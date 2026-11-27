{ lib, pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      # Shell & utilities
      atuin
      asciinema
      overmind

      # Dev tools
      agent-browser
      fdupes
      mkcert
      nmap
      docker-compose
      stripe-cli
      trufflehog
      usage

      # Media
      ffmpeg
      imagemagick
      jhead
      librsvg
      exiftool
      gifsicle
      tesseract

      # CLI utilities
      fastfetch
      # immich-go and stripe-cli each ship a stray bin/cmd beside their real
      # program, and two packages may not provide the same file.
      (lib.lowPrio immich-go)
      rclone
      yt-dlp
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      dockutil
      switchaudio-osx
      vim-darwin
    ];
}
