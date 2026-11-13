#!/usr/bin/env bash

set -euo pipefail

REPO="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
failures=0

fail() {
  echo "  FAIL: $*" >&2
  failures=$((failures + 1))
}

new_dir() {
  realpath "$(mktemp -d)"
}

setup_home() {
  local home=$1 repo=$2
  shift 2
  HOME="$home" bash "$repo/setup-home.sh" "$@" > "$home.log" 2>&1
}

assert_links_to() {
  local home=$1 rel=$2 expected=$3 resolved
  if [[ ! -L "$home/$rel" ]]; then
    fail "$rel is not a symlink"
    return
  fi
  resolved="$(realpath "$home/$rel")"
  [[ "$resolved" == "$expected" ]] || fail "$rel resolves to $resolved, not $expected"
}

links_into() {
  local home=$1 repo=$2 link
  find "$home" -type l | while read -r link; do
    [[ "$(realpath "$link" 2>/dev/null)" != "$repo"/* ]] || echo "$link"
  done | head -3 | tr '\n' ' '
}

write_skill() {
  local dir=$1 extra=${2:-}
  mkdir -p "$dir"
  printf -- '---\nname: %s\n%s---\n\nbody\n' "$(basename "$dir")" "$extra" > "$dir/SKILL.md"
}

make_fixture() {
  local src=$1
  cp -R "$REPO/flake.nix" "$REPO/flake.lock" "$REPO/nix" "$REPO/setup-home.sh" "$src/"
  echo "global instructions" > "$src/GLOBAL_AGENTS.md"
  mkdir -p "$src/skills/work" "$src/skills/vendor-mattpocock" "$src/git"
  echo "[user]" > "$src/git/dot-git-user"
  write_skill "$src/skills/personal/alpha"
  write_skill "$src/skills/vendor/beta"
  write_skill "$src/skills/vendor-auto/gamma" $'disable-model-invocation: true\n'
  write_skill "$src/skills/pending/delta"
}

run_repo_case() {
  local home dangling left
  home="$(new_dir)"
  echo "case: a real run links this repository into an empty home"
  setup_home "$home" "$REPO" || { fail "exit nonzero"; tail -5 "$home.log" >&2; }

  assert_links_to "$home" .zshrc "$REPO/zsh/dot-zshrc"
  assert_links_to "$home" .zsh "$REPO/zsh/dot-zsh"
  assert_links_to "$home" .config/karabiner "$REPO/config/karabiner"
  assert_links_to "$home" .config/herdr/config.toml "$REPO/config/herdr/config.toml"
  assert_links_to "$home" .config/herdr-app/keys.json "$REPO/config/herdr-app/keys.json"
  assert_links_to "$home" .claude/settings.json "$REPO/claude/settings.json"
  assert_links_to "$home" .pi/agent/settings.json "$REPO/pi/settings.json"
  assert_links_to "$home" Library/Spelling/LocalDictionary "$REPO/dictionary/LocalDictionary"
  assert_links_to "$home" .claude/CLAUDE.md "$REPO/GLOBAL_AGENTS.md"
  assert_links_to "$home" .config/opencode/AGENTS.md "$REPO/GLOBAL_AGENTS.md"
  assert_links_to "$home" .pi/agent/AGENTS.md "$REPO/GLOBAL_AGENTS.md"
  assert_links_to "$home" .claude/skills/dotfiles "$REPO/skills/personal/dotfiles"
  assert_links_to "$home" .agents/skills/dotfiles "$REPO/skills/personal/dotfiles"

  [[ "$(ls -A "$home/.config/herdr" | tr '\n' ' ')" == "config.toml " ]] || fail ".config/herdr holds more than config.toml"
  [[ -d "$home/.claude/skills" && ! -L "$home/.claude/skills" ]] || fail ".claude/skills is not a real directory"
  [[ -n "$(find "$home/.ssh" -maxdepth 0 -perm 700)" ]] || fail ".ssh mode is not 700"
  [[ -n "$(find "$home/.gnupg" -maxdepth 0 -perm 700)" ]] || fail ".gnupg mode is not 700"

  [[ -f "$home/.zprezto/init.zsh" ]] || fail ".zprezto holds no init.zsh"
  [[ -f "$home/.zprezto/modules/autosuggestions/external/zsh-autosuggestions.zsh" ]] || fail ".zprezto is missing its own submodules"
  [[ -f "$home/.vim/pack/themes/start/dracula/colors/dracula.vim" ]] || fail "the dracula vim theme is missing"

  dangling="$(find "$home" -type l ! -exec test -e {} \; -print | head -3 | tr '\n' ' ')"
  [[ -z "$dangling" ]] || fail "links to a path that does not exist: $dangling"

  echo "case: -D removes what the real run linked"
  setup_home "$home" "$REPO" -D || { fail "exit nonzero"; tail -5 "$home.log" >&2; }
  left="$(links_into "$home" "$REPO")"
  [[ -z "$left" ]] || fail "-D left: $left"
  [[ ! -e "$home/.zprezto" && ! -e "$home/.vim/pack/themes/start/dracula" ]] || fail "-D left a pinned dependency linked"
  [[ -z "$(ls -A "$home/.claude/skills" 2>/dev/null)" ]] || fail "-D left skills linked"
  rm -rf "$home" "$home.log"
}

run_dry_run_case() {
  local home created
  home="$(new_dir)"
  echo "case: -n links nothing"
  setup_home "$home" "$REPO" -n || { fail "exit nonzero"; tail -5 "$home.log" >&2; }
  created="$(find "$home" -mindepth 1 -not -path "$home/.cache*" -not -path "$home/.nix-*" | head -3 | tr '\n' ' ')"
  [[ -z "$created" ]] || fail "-n created: $created"
  rm -rf "$home" "$home.log"
}

run_skills_case() {
  local src home dir
  src="$(new_dir)"
  home="$(new_dir)"
  echo "case: skills are linked per package with their invocation policy"
  make_fixture "$src"
  setup_home "$home" "$src" || { fail "exit nonzero"; tail -5 "$home.log" >&2; }

  for dir in .claude/skills .agents/skills; do
    assert_links_to "$home" "$dir/alpha" "$src/skills/personal/alpha"
    grep -qx 'disable-model-invocation: true' "$home/$dir/beta/SKILL.md" || fail "$dir/beta is still model-invocable"
    ! grep -q 'disable-model-invocation' "$home/$dir/gamma/SKILL.md" || fail "$dir/gamma is still user-invoked only"
    [[ ! -e "$home/$dir/delta" ]] || fail "$dir/delta was linked from pending/"
  done
  ! grep -q 'disable-model-invocation' "$src/skills/vendor/beta/SKILL.md" || fail "vendor/beta was rewritten in the checkout"
  grep -q 'disable-model-invocation' "$src/skills/vendor-auto/gamma/SKILL.md" || fail "vendor-auto/gamma was rewritten in the checkout"

  assert_links_to "$home" .git-user "$src/git/dot-git-user"
  [[ ! -L "$home/.ssh/config" ]] || fail ".ssh/config was linked although ssh/config does not exist"
  rm -rf "$src" "$home" "$home.log"
}

run_duplicate_skill_case() {
  local src home
  src="$(new_dir)"
  home="$(new_dir)"
  echo "case: a skill name in two packages fails the build"
  make_fixture "$src"
  write_skill "$src/skills/vendor/alpha"
  ! setup_home "$home" "$src" || fail "exit zero"
  grep -q 'conflicting definition values' "$home.log" || { fail "no conflict reported"; tail -5 "$home.log" >&2; }
  [[ ! -e "$home/.claude" ]] || fail "linked despite the conflict"
  rm -rf "$src" "$home" "$home.log"
}

run_existing_file_case() {
  local src home
  src="$(new_dir)"
  home="$(new_dir)"
  echo "case: a real CLAUDE.md stops the run and is left in place"
  make_fixture "$src"
  mkdir -p "$home/.claude"
  echo mine > "$home/.claude/CLAUDE.md"
  ! setup_home "$home" "$src" || fail "exit zero"
  grep -q '\.claude/CLAUDE\.md' "$home.log" || { fail "the file in the way is not named"; tail -5 "$home.log" >&2; }
  [[ ! -L "$home/.claude/CLAUDE.md" && "$(cat "$home/.claude/CLAUDE.md")" == mine ]] || fail "CLAUDE.md was replaced"
  [[ ! -e "$home/.claude/skills" ]] || fail "linked skills despite the file in the way"
  rm -rf "$src" "$home" "$home.log"
}

run_repo_case
run_dry_run_case
run_skills_case
run_duplicate_skill_case
run_existing_file_case

if (( failures > 0 )); then
  echo "$failures failure(s)" >&2
  exit 1
fi
echo PASS
