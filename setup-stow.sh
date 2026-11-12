#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

FLAGS=()
PREPARE_DIRS=1
for arg in "$@"; do
  case "$arg" in
    -D|--delete)
      FLAGS+=("-D")
      PREPARE_DIRS=0
      ;;
    -n|--dry-run)
      FLAGS+=("-n")
      PREPARE_DIRS=0
      ;;
  esac
done

prepare_dir() {
  if (( PREPARE_DIRS )); then
    install -d "$@"
  elif [[ ! -d "${!#}" ]]; then
    echo "skipping: ${!#} does not exist" >&2
    return 1
  fi
}

stow "${FLAGS[@]}" aws
if prepare_dir "$HOME/.claude"; then
  stow "${FLAGS[@]}" claude
fi
stow "${FLAGS[@]}" git
if prepare_dir -m 700 "$HOME/.gnupg"; then
  stow "${FLAGS[@]}" -t "$HOME/.gnupg" gnupg
fi
stow "${FLAGS[@]}" iterm2
if prepare_dir "$HOME/Library/Spelling"; then
  stow "${FLAGS[@]}" -t "$HOME/Library/Spelling" dictionary
fi
stow "${FLAGS[@]}" mise
stow "${FLAGS[@]}" ruby
stow "${FLAGS[@]}" tmux
stow "${FLAGS[@]}" vim
stow "${FLAGS[@]}" zsh
stow "${FLAGS[@]}" zprezto
if prepare_dir "$HOME/.config/herdr" "$HOME/.config/herdr-app"; then
  stow "${FLAGS[@]}" --ignore='herdr/plugins\.json' --ignore='herdr/\.plugins\.lock' -t "$HOME/.config" config
fi
if prepare_dir -m 700 "$HOME/.ssh"; then
  stow "${FLAGS[@]}" -t "$HOME/.ssh" ssh
fi
