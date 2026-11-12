#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

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
mkdir -p "$HOME/.claude" \
  && stow "${FLAGS[@]}" claude
stow "${FLAGS[@]}" git
install -d -m 700 "$HOME/.gnupg" \
  && stow "${FLAGS[@]}" -t "$HOME/.gnupg" gnupg
stow "${FLAGS[@]}" iterm2
mkdir -p "$HOME/Library/Spelling" \
  && stow "${FLAGS[@]}" -t "$HOME/Library/Spelling" dictionary
stow "${FLAGS[@]}" mise
stow "${FLAGS[@]}" ruby
stow "${FLAGS[@]}" tmux
stow "${FLAGS[@]}" vim
stow "${FLAGS[@]}" zsh
stow "${FLAGS[@]}" zprezto
mkdir -p "$HOME/.config/herdr" "$HOME/.config/herdr-app" \
  && stow "${FLAGS[@]}" --ignore='herdr/plugins\.json' --ignore='herdr/\.plugins\.lock' -t "$HOME/.config" config
install -d -m 700 "$HOME/.ssh" \
  && stow "${FLAGS[@]}" -t "$HOME/.ssh" ssh
