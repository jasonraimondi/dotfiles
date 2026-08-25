#!/usr/bin/env bash
#
# Symlink installer: links this repo's skills and shared AI editor config
# (AGENT.md, pi/extensions) into the locations Claude Code and Pi look for them.
#
# Usage: setup.sh [-n|--dry-run] [-D|--delete] [-h|--help]

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# --- sources -----------------------------------------------------------------
# Personal skills live under ./skills/, vendored (downloaded) skills under
# ./vendor/ and ./vendor-auto/. All get linked into the agent skill
# directories. On name collision, the earlier source wins (the later entry is
# skipped with a warning).
SKILLS_SOURCES=(
  "$SCRIPT_DIR/dupe-soup"
  "$SCRIPT_DIR/pending"
  "$SCRIPT_DIR/skills"
  "$SCRIPT_DIR/skills-for-work"
  "$SCRIPT_DIR/vendor"
  "$SCRIPT_DIR/vendor-auto"
)
SKILL_MARKER="SKILL.md"                       # a dir is a skill iff it has this
AGENT_MD_SOURCE="$SCRIPT_DIR/AGENT.md"
PI_EXTENSIONS_SOURCE="$SCRIPT_DIR/pi/extensions"

# --- targets -----------------------------------------------------------------
SKILLS_TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.agents/skills"
)

# "source|destination" pairs for the shared AI editor config.
AI_LINKS=(
  "$AGENT_MD_SOURCE|$HOME/.claude/CLAUDE.md"
  "$AGENT_MD_SOURCE|$HOME/.cursor/rules/agent.md"
  "$AGENT_MD_SOURCE|$HOME/.codeium/windsurf/memories/global_rules.md"
  "$AGENT_MD_SOURCE|$HOME/.junie/guidelines.md"
  "$AGENT_MD_SOURCE|$HOME/.pi/agent/AGENT.md"
  "$PI_EXTENSIONS_SOURCE|$HOME/.pi/agent/extensions"
)

# Records skill names linked on the last successful run, so renamed/removed
# skills get their stale links cleaned up next time. Kept outside the target
# dirs so it can't collide with a `ln -s skills ~/.claude/skills` install.
MANIFEST="${XDG_STATE_HOME:-$HOME/.local/state}/jason-skills/synced-skills"
LEGACY_MANIFEST="$HOME/.claude/skills/.dotfiles-skills-manifest"

DELETE_MODE=false
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage: setup.sh [-n|--dry-run] [-D|--delete] [-h|--help]

  (no args)        symlink skills + shared AI editor config into place
  -n, --dry-run    print what would change without touching anything
  -D, --delete     remove the symlinks this script created
  -h, --help       show this message
EOF
}

log()  { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }

# Remove a path, but only if it's a symlink we plausibly created. Real files or
# directories at that location are left alone with a warning.
unlink_path() {
  local path="$1"
  [[ -e "$path" || -L "$path" ]] || return 0
  if [[ ! -L "$path" ]]; then
    warn "not a symlink, leaving in place: $path"
    return 0
  fi
  if [[ "$DRY_RUN" == true ]]; then
    log "rm $path"
  else
    rm "$path"
    log "removed $path"
  fi
}

# Point destination at source. Skips (with a warning) if the source is missing;
# backs up a pre-existing real file/dir to .bak before replacing it.
link_path() {
  local source="$1" destination="$2"
  if [[ ! -e "$source" ]]; then
    warn "source missing, skipping: $source"
    return 0
  fi
  if [[ -e "$destination" && ! -L "$destination" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      log "mv $destination $destination.bak"
    else
      warn "backing up existing $destination -> $destination.bak"
      mv "$destination" "$destination.bak"
    fi
  fi
  if [[ "$DRY_RUN" == true ]]; then
    log "ln -sfn $source $destination"
    return 0
  fi
  mkdir -p "$(dirname "$destination")"
  ln -sfn "$source" "$destination"
  log "linked $destination -> $source"
}

# How a source's skills should be exposed to the agent:
#   disable — user-invoked only (frontmatter gets disable-model-invocation: true)
#   auto    — model-invoked (the key is stripped so the agent can fire it)
#   none    — leave the frontmatter alone
invocation_policy_for() {
  case "$1" in
    "$SCRIPT_DIR/pending")     printf 'disable' ;;
    "$SCRIPT_DIR/vendor")      printf 'disable' ;;
    "$SCRIPT_DIR/vendor-auto") printf 'auto' ;;
    *)                         printf 'none' ;;
  esac
}

# Enforce a source's invocation policy on a skill. Skills are symlinked rather
# than copied, so the only place to set this is the SKILL.md in this repo —
# expect these edits to show up in `git status`.
apply_invocation_policy() {
  local skill_dir="$1" policy="$2" file tmp
  [[ "$policy" == "none" ]] && return 0
  file="$skill_dir/$SKILL_MARKER"
  if [[ "$(head -n 1 "$file")" != "---" ]]; then
    warn "no frontmatter, skipping invocation policy: $file"
    return 0
  fi

  tmp="$(mktemp "${TMPDIR:-/tmp}/skill-frontmatter.XXXXXX")"
  awk -v policy="$policy" '
    NR == 1 && $0 == "---" { in_fm = 1; print; next }
    in_fm && $0 == "---" {
      if (policy == "disable" && !seen) print "disable-model-invocation: true"
      in_fm = 0; print; next
    }
    in_fm && /^disable-model-invocation:/ {
      seen = 1
      if (policy == "disable") print "disable-model-invocation: true"
      next
    }
    { print }
  ' "$file" > "$tmp"

  if cmp -s "$file" "$tmp"; then
    rm -f "$tmp"
    return 0
  fi
  if [[ "$DRY_RUN" == true ]]; then
    rm -f "$tmp"
    log "set invocation policy '$policy' in $file"
    return 0
  fi
  cat "$tmp" > "$file"
  rm -f "$tmp"
  log "set invocation policy '$policy' in $file"
}

# Print "<name>|<source_dir>" for each skill directory across all sources
# (those containing $SKILL_MARKER). Earlier sources win on name collision: if
# the same skill name appears in both ./skills/ and ./vendor/, the personal
# one is emitted and the vendor one is skipped with a warning.
list_skills() {
  local source dir name
  declare -A seen=()
  for source in "${SKILLS_SOURCES[@]}"; do
    [[ -d "$source" ]] || continue
    for dir in "$source"/*/; do
      [[ -f "$dir$SKILL_MARKER" ]] || continue
      name="$(basename "$dir")"
      if [[ -n "${seen[$name]:-}" ]]; then
        warn "duplicate skill name '$name' in $source — keeping ${seen[$name]}"
        continue
      fi
      seen[$name]="$source"
      printf '%s|%s\n' "$name" "$source"
    done
  done
}

# Remove links recorded by previous runs (current and legacy manifest), then
# delete those manifests so the next run can rebuild from scratch.
cleanup_stale_skills() {
  local manifest name dir
  for manifest in "$MANIFEST" "$LEGACY_MANIFEST"; do
    [[ -f "$manifest" ]] || continue
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      if [[ ! "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
        warn "ignoring suspicious manifest entry: $name"
        continue
      fi
      for dir in "${SKILLS_TARGETS[@]}"; do
        unlink_path "$dir/$name"
      done
    done < "$manifest"
    if [[ "$DRY_RUN" == true ]]; then
      log "rm $manifest"
    else
      rm "$manifest"
    fi
  done
}

# Write the manifest atomically (temp file + mv) so an interrupted run never
# leaves us without a record of what to clean up.
write_manifest() {
  local names="$1" tmp
  if [[ "$DRY_RUN" == true ]]; then
    log "write $(printf '%s' "$names" | grep -c . || true) skill name(s) to $MANIFEST"
    return 0
  fi
  mkdir -p "$(dirname "$MANIFEST")"
  tmp="$(mktemp "$MANIFEST.XXXXXX")"
  printf '%s' "$names" > "$tmp"
  mv "$tmp" "$MANIFEST"
}

link_ai_config() {
  local pair source destination
  for pair in "${AI_LINKS[@]}"; do
    source="${pair%%|*}"
    destination="${pair#*|}"
    if [[ "$DELETE_MODE" == true ]]; then
      unlink_path "$destination"
    else
      link_path "$source" "$destination"
    fi
  done
}

sync_skills() {
  local source found=false
  for source in "${SKILLS_SOURCES[@]}"; do
    [[ -d "$source" ]] && found=true
  done
  if [[ "$found" != true ]]; then
    warn "no skills sources found: ${SKILLS_SOURCES[*]}"
    return 1
  fi

  # Always clear out the previous run's links first; that handles skills that
  # were since renamed, deleted, or moved between ./skills/ and ./vendor/.
  cleanup_stale_skills

  local skills entry name src dir names=""
  skills="$(list_skills)"

  if [[ "$DELETE_MODE" == true ]]; then
    while IFS= read -r entry; do
      [[ -z "$entry" ]] && continue
      name="${entry%%|*}"
      for dir in "${SKILLS_TARGETS[@]}"; do
        unlink_path "$dir/$name"
      done
    done <<< "$skills"
    return 0
  fi

  if [[ -z "$skills" ]]; then
    warn "no skills (dirs containing $SKILL_MARKER) found under ${SKILLS_SOURCES[*]}"
    return 1
  fi

  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    name="${entry%%|*}"
    src="${entry#*|}"
    apply_invocation_policy "$src/$name" "$(invocation_policy_for "$src")"
    for dir in "${SKILLS_TARGETS[@]}"; do
      link_path "$src/$name" "$dir/$name"
    done
    names+="$name"$'\n'
  done <<< "$skills"

  write_manifest "$names"
}

main() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      -D|--delete)  DELETE_MODE=true ;;
      -n|--dry-run) DRY_RUN=true ;;
      -h|--help)    usage; exit 0 ;;
      *) warn "unknown argument: $arg"; usage >&2; exit 2 ;;
    esac
  done

  link_ai_config
  sync_skills
}

main "$@"
