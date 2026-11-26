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
      rsync
      zsh

      # Shell & utilities
      direnv
      mise
      fd
      fzf
      jq
      moreutils
      mtr
      ripgrep
      safe-rm
      go-task
      tmux
      tree
      watch
      wget
      yq-go

      # Dev tools
      gitleaks
      shellcheck

      # Git
      diff-so-fancy
      difftastic
      gh
      git
      git-extras
      git-lfs
      lazygit
    ]
    # On macOS Homebrew supplies gnupg; Linux has no Homebrew.
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      coreutils
      gnused
      gnugrep
      gnupg
      pinentry-curses
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      coreutils-prefixed
      (gPrefixed gnused)
      (gPrefixed gnugrep)
    ];
}
