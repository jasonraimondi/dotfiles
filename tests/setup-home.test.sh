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
  HOME="$home" DOTFILES_NO_LAUNCHD=1 bash "$repo/setup-home.sh" "$@" > "$home.log" 2>&1
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

# Nix and Home Manager keep state of their own in the home they activate into.
find_outside_nix_state() {
  local home=$1
  shift
  find "$home" -mindepth 1 \
    -not -path "$home/.cache*" -not -path "$home/.local*" -not -path "$home/.nix-*" "$@"
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
  mkdir -p "$src/skills/vendor-mattpocock" "$src/git"
  echo "[user]" > "$src/git/dot-git-user"
  write_skill "$src/skills/personal/alpha"
  write_skill "$src/skills/work/epsilon"
  write_skill "$src/skills/vendor/beta"
  write_skill "$src/skills/vendor-auto/gamma" $'disable-model-invocation: true\n'
  write_skill "$src/skills/pending/delta"
}

run_repo_case() {
  local home dangling left profile
  home="$(new_dir)"
  echo "case: a real run links this repository into an empty home"
  setup_home "$home" "$REPO" || { fail "exit nonzero"; tail -5 "$home.log" >&2; }

  assert_links_to "$home" .zshrc "$REPO/zsh/dot-zshrc"
  assert_links_to "$home" .zsh "$REPO/zsh/dot-zsh"
  assert_links_to "$home" .config/herdr/config.toml "$REPO/config/herdr/config.toml"
  assert_links_to "$home" .config/herdr-app/keys.json "$REPO/config/herdr-app/keys.json"
  assert_links_to "$home" .claude/settings.json "$REPO/claude/settings.json"
  assert_links_to "$home" .pi/agent/settings.json "$REPO/pi/settings.json"
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

  dangling="$(find_outside_nix_state "$home" -type l ! -exec test -e {} \; -print | head -3 | tr '\n' ' ')"
  [[ -z "$dangling" ]] || fail "links to a path that does not exist: $dangling"

  profile="$home/.nix-profile/bin"
  "$profile/rg" --version > /dev/null 2>&1 || fail "ripgrep does not run from the profile"
  if [[ "$(uname)" == Darwin ]]; then
    assert_links_to "$home" .config/karabiner "$REPO/config/karabiner"
    [[ ! -e "$home/Library/LaunchAgents/org.nix-community.home.herdr-core-serve.plist" ]] || fail "a test run installed the herdr-core LaunchAgent"
    assert_links_to "$home" Library/Spelling/LocalDictionary "$REPO/dictionary/LocalDictionary"
    assert_links_to "$home" .gnupg/gpg-agent.conf "$REPO/gnupg/gpg-agent.conf"
    "$profile/gsed" --version 2> /dev/null | grep -q 'GNU sed' || fail "gsed is not GNU sed"
    "$profile/ggrep" --version 2> /dev/null | grep -q 'GNU grep' || fail "ggrep is not GNU grep"
    [[ -x "$profile/gls" ]] || fail "coreutils is not installed with the g prefix"
    [[ ! -e "$profile/sed" && ! -e "$profile/grep" && ! -e "$profile/ls" ]] || fail "a GNU tool shadows the one macOS ships"
    [[ ! -L "$home/.profile" && ! -L "$home/.bashrc" ]] || fail "a Linux-only shell profile is linked on macOS"
  else
    [[ ! -e "$home/.config/karabiner" && ! -e "$home/Library" ]] || fail "a macOS-only path is linked on Linux"
    grep -q '^pinentry-program /nix/store/.*/bin/pinentry-curses$' "$home/.gnupg/gpg-agent.conf" || fail "gpg-agent.conf does not name pinentry-curses on Linux"
    "$profile/gpg" --version > /dev/null 2>&1 || fail "gpg does not run from the profile on Linux"
    grep -qx 'default-cache-ttl 28800' "$home/.gnupg/gpg-agent.conf" || fail "gpg-agent.conf lost its cache settings on Linux"
    "$profile/sed" --version 2> /dev/null | grep -q 'GNU sed' || fail "sed is not GNU sed"
    "$profile/grep" --version 2> /dev/null | grep -q 'GNU grep' || fail "grep is not GNU grep"
    [[ -x "$profile/ls" && ! -e "$profile/gsed" ]] || fail "GNU tools are installed with the g prefix on Linux"
    assert_links_to "$home" .profile "$REPO/bash/dot-profile"
    assert_links_to "$home" .bashrc "$REPO/bash/dot-bashrc"
    # The distribution's /etc files may load Nix too, so DOTFILES_HOME is the
    # proof that the linked file ran. BASH_ENV stands in for sshd running a
    # command, the one case where a non-interactive bash reads ~/.bashrc. Only
    # the last line counts, since /etc/profile.d scripts may print a banner.
    for shell in "bash -l" "bash -i" "BASH_ENV=$home/.bashrc bash" "sh -l"; do
      shell_env="$(env -i HOME="$home" PATH=/usr/bin:/bin $shell -c 'echo "$DOTFILES_HOME $PATH"' 2> /dev/null | tail -n 1)" || true
      [[ "$shell_env" == "$home/dotfiles "* ]] || fail "$shell does not read the linked profile: $shell_env"
      [[ ":${shell_env#* }:" == *":$profile:"* ]] || fail "$shell does not put ~/.nix-profile/bin on PATH: $shell_env"
    done
  fi

  echo "case: -D removes what the real run linked"
  setup_home "$home" "$REPO" -D || { fail "exit nonzero"; tail -5 "$home.log" >&2; }
  left="$(links_into "$home" "$REPO")"
  [[ -z "$left" ]] || fail "-D left: $left"
  [[ ! -e "$home/.zprezto" && ! -e "$home/.vim/pack/themes/start/dracula" ]] || fail "-D left a pinned dependency linked"
  [[ -z "$(ls -A "$home/.claude/skills" 2>/dev/null)" ]] || fail "-D left skills linked"
  [[ -x "$profile/rg" ]] || fail "-D uninstalled the packages"
  rm -rf "$home" "$home.log"
}

run_dry_run_case() {
  local home created
  home="$(new_dir)"
  echo "case: -n links nothing"
  setup_home "$home" "$REPO" -n || { fail "exit nonzero"; tail -5 "$home.log" >&2; }
  created="$(find_outside_nix_state "$home" | head -3 | tr '\n' ' ')"
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
    assert_links_to "$home" "$dir/epsilon" "$src/skills/work/epsilon"
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

run_server_case() {
  local home left profile path
  home="$(new_dir)"
  echo "case: -p server links the core dotfiles and leaves out the desktop ones"
  setup_home "$home" "$REPO" -p server || { fail "exit nonzero"; tail -5 "$home.log" >&2; }

  assert_links_to "$home" .zshrc "$REPO/zsh/dot-zshrc"
  assert_links_to "$home" .zsh "$REPO/zsh/dot-zsh"
  assert_links_to "$home" .zprofile "$REPO/zprezto/dot-zprofile"
  assert_links_to "$home" .gitconfig "$REPO/git/dot-gitconfig"
  assert_links_to "$home" .tmux.conf "$REPO/tmux/dot-tmux.conf"
  assert_links_to "$home" .vimrc "$REPO/vim/dot-vimrc"
  assert_links_to "$home" .config/gh/config.yml "$REPO/config/gh/config.yml"
  assert_links_to "$home" .config/nix/nix.conf "$REPO/config/nix/nix.conf"
  assert_links_to "$home" .claude/CLAUDE.md "$REPO/GLOBAL_AGENTS.md"
  assert_links_to "$home" .config/opencode/AGENTS.md "$REPO/GLOBAL_AGENTS.md"
  assert_links_to "$home" .pi/agent/AGENTS.md "$REPO/GLOBAL_AGENTS.md"
  assert_links_to "$home" .claude/skills/dotfiles "$REPO/skills/personal/dotfiles"
  assert_links_to "$home" .agents/skills/dotfiles "$REPO/skills/personal/dotfiles"
  [[ -f "$home/.zprezto/init.zsh" ]] || fail ".zprezto holds no init.zsh"
  [[ -f "$home/.vim/pack/themes/start/dracula/colors/dracula.vim" ]] || fail "the dracula vim theme is missing"
  [[ -n "$(find "$home/.gnupg" -maxdepth 0 -perm 700)" ]] || fail ".gnupg mode is not 700"
  if [[ "$(uname)" != Darwin ]]; then
    grep -q '^pinentry-program /nix/store/.*/bin/pinentry-curses$' "$home/.gnupg/gpg-agent.conf" || fail "gpg-agent.conf does not name pinentry-curses on Linux"
  fi

  for path in .config/zed .config/herdr .config/herdr-app .config/mise .config/atuin .claude/settings.json .claude/hooks .pi/agent/settings.json .pi/agent/extensions .config/karabiner Library; do
    [[ ! -e "$home/$path" ]] || fail "$path is linked on a server"
  done
  [[ -z "$(links_into "$home" "$REPO/skills/work")" ]] || fail "a work skill is linked on a server"

  profile="$home/.nix-profile/bin"
  "$profile/rg" --version > /dev/null 2>&1 || fail "ripgrep does not run from the profile"
  [[ ! -e "$profile/atuin" && ! -e "$profile/ffmpeg" ]] || fail "a desktop package is installed on a server"

  echo "case: -p server -D removes what the server run linked"
  setup_home "$home" "$REPO" -p server -D || { fail "exit nonzero"; tail -5 "$home.log" >&2; }
  left="$(links_into "$home" "$REPO")"
  [[ -z "$left" ]] || fail "-D left: $left"
  [[ -x "$profile/rg" ]] || fail "-D uninstalled the packages"
  [[ ! -e "$profile/atuin" ]] || fail "-D installed the desktop packages on a server"
  rm -rf "$home" "$home.log"
}

run_server_skills_case() {
  local src home dir
  src="$(new_dir)"
  home="$(new_dir)"
  echo "case: -p server links every skill package but work"
  make_fixture "$src"
  setup_home "$home" "$src" -p server || { fail "exit nonzero"; tail -5 "$home.log" >&2; }
  for dir in .claude/skills .agents/skills; do
    assert_links_to "$home" "$dir/alpha" "$src/skills/personal/alpha"
    [[ -f "$home/$dir/beta/SKILL.md" ]] || fail "$dir/beta from vendor/ is missing"
    [[ -f "$home/$dir/gamma/SKILL.md" ]] || fail "$dir/gamma from vendor-auto/ is missing"
    [[ ! -e "$home/$dir/epsilon" ]] || fail "$dir/epsilon was linked from work/"
  done
  rm -rf "$src" "$home" "$home.log"
}

run_unknown_profile_case() {
  local home
  home="$(new_dir)"
  echo "case: an unknown profile is rejected before anything is built"
  ! setup_home "$home" "$REPO" -p unlinked || fail "exit zero"
  grep -q 'unknown profile: unlinked' "$home.log" || { fail "the profile is not named"; tail -5 "$home.log" >&2; }
  [[ -z "$(find_outside_nix_state "$home" | head -3)" ]] || fail "created files for an unknown profile"
  rm -rf "$home" "$home.log"
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

run_backup_case() {
  local src home
  src="$(new_dir)"
  home="$(new_dir)"
  echo "case: -b moves a real CLAUDE.md aside and links"
  make_fixture "$src"
  mkdir -p "$home/.claude"
  echo mine > "$home/.claude/CLAUDE.md"
  setup_home "$home" "$src" -b || { fail "exit nonzero"; tail -5 "$home.log" >&2; }
  assert_links_to "$home" .claude/CLAUDE.md "$src/GLOBAL_AGENTS.md"
  [[ "$(cat "$home/.claude/CLAUDE.md.hm-backup" 2>/dev/null)" == mine ]] || fail "CLAUDE.md was not backed up"
  rm -rf "$src" "$home" "$home.log"
}

run_repo_case
run_dry_run_case
run_skills_case
run_server_case
run_server_skills_case
run_unknown_profile_case
run_duplicate_skill_case
run_existing_file_case
run_backup_case

if (( failures > 0 )); then
  echo "$failures failure(s)" >&2
  exit 1
fi
echo PASS
