{ lib, pkgs, ... }:
let
  # Homebrew installs GNU sed and grep as gsed and ggrep, which leaves the names
  # sed and grep to the BSD tools macOS ships. nixpkgs has no prefixed build of
  # either, unlike coreutils.
  gPrefixed =
    package:
    pkgs.runCommand "g-prefixed-${package.pname}" { } ''
      mkdir -p $out/bin
      for program in ${package}/bin/*; do
        ln -s "$program" "$out/bin/g$(basename "$program")"
      done
    '';
in
{
  home.packages =
    with pkgs;
    [
      # Core
      bashInteractive
      coreutils-prefixed
      (gPrefixed gnused)
      (gPrefixed gnugrep)
      rsync
      zsh

      # Shell & utilities
      atuin
      direnv
      asciinema
      fd
      fzf
      jq
      moreutils
      mtr
      overmind
      ripgrep
      safe-rm
      go-task
      tmux
      tree
      watch
      wget
      yq-go

      # Dev tools
      agent-browser
      fdupes
      mkcert
      nmap
      docker-compose
      gitleaks
      shellcheck
      stripe-cli
      trufflehog
      usage

      # Git
      diff-so-fancy
      difftastic
      gh
      git
      git-extras
      git-lfs
      lazygit

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
