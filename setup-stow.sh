#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AGENT_MD_SOURCE="$SCRIPT_DIR/ai/AGENT.md"
PI_EXTENSIONS_SOURCE="$SCRIPT_DIR/ai/pi/extensions"

FLAGS=()
DELETE_MODE=false
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    -D|--delete)
      FLAGS+=("-D")
      DELETE_MODE=true
      ;;
    -n|--dry-run)
      FLAGS+=("-n")
      DRY_RUN=true
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
