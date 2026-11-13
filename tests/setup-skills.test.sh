#!/usr/bin/env bash

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

fail() {
  echo "  FAIL: $*" >&2
  failures=$((failures + 1))
}

write_skill() {
  local dir=$1 extra=${2:-}
  mkdir -p "$dir"
  printf -- '---\nname: %s\n%s---\n\nbody\n' "$(basename "$dir")" "$extra" > "$dir/SKILL.md"
}

make_fixture() {
  local src=$1
  cp "$REPO/setup-skills.sh" "$src/"
  echo "global instructions" > "$src/GLOBAL_AGENTS.md"
  mkdir -p "$src/skills/work" "$src/skills/vendor-mattpocock"
  write_skill "$src/skills/personal/alpha"
  write_skill "$src/skills/vendor/beta"
  write_skill "$src/skills/vendor-auto/gamma" $'disable-model-invocation: true\n'
  write_skill "$src/skills/pending/delta"
}

resolved() {
  (cd "$(dirname "$1")" && realpath "$(readlink "$1")")
}

run_real_case() {
  local src home dir dest
  src="$(mktemp -d)"; src="$(realpath "$src")"
  home="$(mktemp -d)"
  echo "case: real run links installed packages and the global instructions"
  make_fixture "$src"
  (cd "$home" && HOME="$home" bash "$src/setup-skills.sh") > "$home/.out" 2>&1 \
    || { fail "exit nonzero"; tail -5 "$home/.out" >&2; }

  for dir in .claude/skills .agents/skills; do
    [[ "$(resolved "$home/$dir/alpha")" == "$src/skills/personal/alpha" ]] || fail "$dir/alpha is not linked to personal/alpha"
    [[ -L "$home/$dir/beta" && -L "$home/$dir/gamma" ]] || fail "$dir is missing a vendor skill"
    [[ ! -e "$home/$dir/delta" ]] || fail "$dir/delta was linked from pending/"
  done
  for dest in .claude/CLAUDE.md .config/opencode/AGENTS.md .pi/agent/AGENTS.md; do
    [[ "$(resolved "$home/$dest")" == "$src/GLOBAL_AGENTS.md" ]] || fail "$dest is not linked to GLOBAL_AGENTS.md"
  done
  grep -qx 'disable-model-invocation: true' "$src/skills/vendor/beta/SKILL.md" || fail "vendor/beta is still model-invocable"
  ! grep -q 'disable-model-invocation' "$src/skills/vendor-auto/gamma/SKILL.md" || fail "vendor-auto/gamma is still user-invoked only"
  ! grep -q 'disable-model-invocation' "$src/skills/personal/alpha/SKILL.md" || fail "personal/alpha frontmatter was rewritten"

  echo "case: -D removes what the real run linked"
  (cd "$home" && HOME="$home" bash "$src/setup-skills.sh" -D) > "$home/.out" 2>&1 \
    || { fail "exit nonzero"; tail -5 "$home/.out" >&2; }
  [[ -z "$(find "$home" -type l | head -1)" ]] || fail "-D left: $(find "$home" -type l | head -3 | tr '\n' ' ')"
  rm -rf "$src" "$home"
}

run_dry_run_case() {
  local src home created
  src="$(mktemp -d)"
  home="$(mktemp -d)"
  echo "case: -n links nothing and rewrites no frontmatter"
  make_fixture "$src"
  mkdir -p "$home/.claude/skills" "$home/.agents/skills"
  (cd "$home" && HOME="$home" bash "$src/setup-skills.sh" -n) > "$home/.out" 2>&1 \
    || { fail "exit nonzero"; tail -5 "$home/.out" >&2; }
  created="$(find "$home" -mindepth 1 -not -name .out -not -name .claude -not -name .agents -not -name skills | head -3)"
  [[ -z "$created" ]] || fail "-n created: $created"
  ! grep -q 'disable-model-invocation' "$src/skills/vendor/beta/SKILL.md" || fail "-n rewrote vendor/beta"
  rm -rf "$src" "$home"
}

run_existing_file_case() {
  local src home
  src="$(mktemp -d)"
  home="$(mktemp -d)"
  echo "case: a real CLAUDE.md is left in place"
  make_fixture "$src"
  mkdir -p "$home/.claude"
  echo mine > "$home/.claude/CLAUDE.md"
  (cd "$home" && HOME="$home" bash "$src/setup-skills.sh") > "$home/.out" 2>&1 \
    || { fail "exit nonzero"; tail -5 "$home/.out" >&2; }
  [[ ! -L "$home/.claude/CLAUDE.md" && "$(cat "$home/.claude/CLAUDE.md")" == mine ]] || fail "CLAUDE.md was replaced"
  rm -rf "$src" "$home"
}

run_repo_packages_case() {
  local home
  home="$(mktemp -d)"
  echo "case: the repo's installed packages hold no duplicate skill names"
  mkdir -p "$home/.claude/skills" "$home/.agents/skills"
  (cd "$home" && HOME="$home" bash "$REPO/setup-skills.sh" -n) > "$home/.out" 2>&1 \
    || { fail "dry run against the repo failed"; tail -5 "$home/.out" >&2; }
  rm -rf "$home"
}

run_real_case
run_dry_run_case
run_existing_file_case
run_repo_packages_case

if (( failures > 0 )); then
  echo "$failures failure(s)" >&2
  exit 1
fi
echo PASS
