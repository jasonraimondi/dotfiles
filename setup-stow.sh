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

manage_link() {
  local source="$1"
  local destination="$2"

  if [[ "$DRY_RUN" == true ]]; then
    if [[ "$DELETE_MODE" == true ]]; then
      echo "dry-run: rm -f $destination"
    else
      echo "dry-run: ln -sfn $source $destination"
    fi
    return 0
  fi

  if [[ "$DELETE_MODE" == true ]]; then
    rm -f "$destination"
    return 0
  fi

  mkdir -p "$(dirname "$destination")"
  ln -sfn "$source" "$destination"
}

# AI
manage_link "$AGENT_MD_SOURCE" "$HOME/.claude/CLAUDE.md"
manage_link "$AGENT_MD_SOURCE" "$HOME/.cursor/rules/agent.md"
manage_link "$AGENT_MD_SOURCE" "$HOME/.codeium/windsurf/memories/global_rules.md"
manage_link "$AGENT_MD_SOURCE" "$HOME/.junie/guidelines.md"
manage_link "$AGENT_MD_SOURCE" "$HOME/.pi/agent/AGENT.md"
manage_link "$PI_EXTENSIONS_SOURCE" "$HOME/.pi/agent/extensions"
