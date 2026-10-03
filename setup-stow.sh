#!/usr/bin/env bash

set -euo pipefail

FLAGS=()
for arg in "$@"; do
  case "$arg" in
    -D|--delete)
      FLAGS+=("-D")
      ;;
    -n|--dry-run)
      FLAGS+=("-n")
      ;;
  esac
done

stow "${FLAGS[@]}" aws
stow "${FLAGS[@]}" git
stow "${FLAGS[@]}" iterm2
stow "${FLAGS[@]}" -t "$HOME/Library/Spelling" dictionary
stow "${FLAGS[@]}" mackup
stow "${FLAGS[@]}" mise
stow "${FLAGS[@]}" ruby
stow "${FLAGS[@]}" tmux
stow "${FLAGS[@]}" vim
stow "${FLAGS[@]}" zsh
stow "${FLAGS[@]}" zprezto
mkdir -p "$HOME/.config" \
  && stow "${FLAGS[@]}" -t "$HOME/.config" config
mkdir -p "$HOME/.ssh" \
  && stow "${FLAGS[@]}" -t "$HOME/.ssh" ssh
