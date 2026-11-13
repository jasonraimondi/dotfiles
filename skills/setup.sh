#!/usr/bin/env bash
#
# Symlinks this repo's skills and shared AI editor config into the locations
# each agent expects. Skills, Pi, and Claude settings go through GNU Stow;
# AGENTS.md is linked by hand because it lands under several different names.
#
# Usage: setup.sh [-n|--dry-run] [-D|--delete] [-h|--help]

set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# A skill name in two packages is a stow conflict, so the run aborts.
SKILL_PACKAGES=(skills skills-for-work vendor vendor-auto vendor-mattpocock)
SKILL_TARGETS=("$HOME/.claude/skills" "$HOME/.agents/skills")

AGENTS_MD_TARGETS=(
  "$HOME/.claude/CLAUDE.md"
  "$HOME/.pi/agent/AGENTS.md"
)

DELETE_MODE=false
DRY_RUN=false
STOW_FLAGS=(--restow --ignore='\.DS_Store' --ignore='\.bak$')

usage() {
  cat <<'EOF'
Usage: setup.sh [-n|--dry-run] [-D|--delete] [-h|--help]

  (no args)        symlink skills + shared AI editor config into place
  -n, --dry-run    print what would change without touching anything
  -D, --delete     remove the symlinks this script created
  -h, --help       show this message
EOF
}

warn() { printf 'warning: %s\n' "$*" >&2; }

run() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '%s\n' "$*"
  else
    "$@"
  fi
}

stow_into() {
  local target="$1"; shift
  run mkdir -p "$target"
  stow "${STOW_FLAGS[@]}" -d "$REPO" -t "$target" "$@"
}

link_agents_md() {
  local dest
  for dest in "${AGENTS_MD_TARGETS[@]}"; do
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      warn "not a symlink, leaving in place: $dest"
    elif [[ "$DELETE_MODE" == true ]]; then
      [[ -L "$dest" ]] && run rm "$dest"
    else
      run mkdir -p "$(dirname "$dest")"
      run ln -sfn "$REPO/AGENTS.md" "$dest"
    fi
  done
}

# Skills are symlinked rather than copied, so the only place to set this is the
# SKILL.md in this repo — expect these edits to show up in `git status`.
#   disable — user-invoked only (frontmatter gets disable-model-invocation: true)
#   auto    — model-invoked (the key is stripped so the agent can fire it)
apply_invocation_policy() {
  local file="$1" policy="$2" tmp
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

  if ! cmp -s "$file" "$tmp"; then
    printf "set invocation policy '%s' in %s\n" "$policy" "$file"
    [[ "$DRY_RUN" == true ]] || cat "$tmp" > "$file"
  fi
  rm -f "$tmp"
}

apply_invocation_policies() {
  local file
  for file in "$REPO"/vendor/*/SKILL.md; do
    apply_invocation_policy "$file" disable
  done
  for file in "$REPO"/vendor-auto/*/SKILL.md; do
    apply_invocation_policy "$file" auto
  done
}

main() {
  local arg target
  for arg in "$@"; do
    case "$arg" in
      -D|--delete)  DELETE_MODE=true; STOW_FLAGS+=(--delete) ;;
      -n|--dry-run) DRY_RUN=true; STOW_FLAGS+=(--no) ;;
      -h|--help)    usage; exit 0 ;;
      *) warn "unknown argument: $arg"; usage >&2; exit 2 ;;
    esac
  done

  # stow reads .stowrc from the working directory, and the dotfiles one a level
  # up sets --dotfiles and a $HOME target meant for the other packages.
  cd "$REPO"

  [[ "$DELETE_MODE" == true ]] || apply_invocation_policies
  for target in "${SKILL_TARGETS[@]}"; do
    stow_into "$target" "${SKILL_PACKAGES[@]}"
  done
  stow_into "$HOME/.pi/agent" pi
  stow_into "$HOME/.claude" claude
  link_agents_md
}

main "$@"
