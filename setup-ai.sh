#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AGENT_MD_SOURCE="$SCRIPT_DIR/ai/AGENT.md"
PI_EXTENSIONS_SOURCE="$SCRIPT_DIR/ai/pi/extensions"
SKILLS_SOURCE="$HOME/Code/jason/skills/skills"
SKILLS_TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.pi/agent/skills"
)
SKILLS_MANIFEST="$HOME/.claude/skills/.dotfiles-skills-manifest"

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

mkdir -p "$HOME/.config" \
  && stow "${FLAGS[@]}" -t "$HOME/.config" config

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

  echo "\$ ln -sfn $source $destination"
  ln -sfn "$source" "$destination"
}

# AI
manage_link "$AGENT_MD_SOURCE" "$HOME/.claude/CLAUDE.md"
manage_link "$AGENT_MD_SOURCE" "$HOME/.cursor/rules/agent.md"
manage_link "$AGENT_MD_SOURCE" "$HOME/.codeium/windsurf/memories/global_rules.md"
manage_link "$AGENT_MD_SOURCE" "$HOME/.junie/guidelines.md"
manage_link "$AGENT_MD_SOURCE" "$HOME/.pi/agent/AGENT.md"
manage_link "$PI_EXTENSIONS_SOURCE" "$HOME/.pi/agent/extensions"

# Skills — symlink each subdir of $SKILLS_SOURCE into each $SKILLS_TARGETS dir.
# $SKILLS_MANIFEST tracks previously-synced skill names so removed/renamed
# skills get cleaned up on the next run.
if [[ -f "$SKILLS_MANIFEST" ]]; then
  while IFS= read -r prev_skill; do
    [[ -z "$prev_skill" ]] && continue
    for target_dir in "${SKILLS_TARGETS[@]}"; do
      target="$target_dir/$prev_skill"
      if [[ "$DRY_RUN" == true ]]; then
        echo "dry-run: rm -f $target"
      else
        rm -f "$target"
      fi
    done
  done < "$SKILLS_MANIFEST"
  if [[ "$DRY_RUN" == true ]]; then
    echo "dry-run: rm -f $SKILLS_MANIFEST"
  else
    rm -f "$SKILLS_MANIFEST"
  fi
fi

if [[ "$DELETE_MODE" == false ]]; then
  if [[ -d "$SKILLS_SOURCE" ]]; then
    new_manifest=""
    for skill_dir in "$SKILLS_SOURCE"/*/; do
      [[ -d "$skill_dir" ]] || continue
      skill_name="$(basename "$skill_dir")"
      for target_dir in "${SKILLS_TARGETS[@]}"; do
        manage_link "${skill_dir%/}" "$target_dir/$skill_name"
      done
      new_manifest+="$skill_name"$'\n'
    done
    if [[ "$DRY_RUN" == true ]]; then
      echo "dry-run: write $(printf '%s' "$new_manifest" | grep -c '^') skills to $SKILLS_MANIFEST"
    elif [[ -n "$new_manifest" ]]; then
      mkdir -p "$(dirname "$SKILLS_MANIFEST")"
      printf '%s' "$new_manifest" > "$SKILLS_MANIFEST"
    fi
  else
    echo "warning: skills source not found at $SKILLS_SOURCE" >&2
  fi
fi
