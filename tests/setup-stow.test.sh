#!/usr/bin/env bash

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

fail() {
  echo "  FAIL: $*" >&2
  failures=$((failures + 1))
}

assert_link_into_repo() {
  local home=$1 rel=$2 resolved
  if [[ ! -L "$home/$rel" ]]; then
    fail "$rel is not a symlink"
    return
  fi
  resolved="$(cd "$(dirname "$home/$rel")" && realpath "$(readlink "$home/$rel")")"
  [[ "$resolved" == "$REPO"/* ]] || fail "$rel resolves to $resolved, outside $REPO"
}

run_case() {
  local label=$1 cwd_mode=$2 mode=$3
  local home cwd
  home="$(mktemp -d)"
  if [[ "$cwd_mode" == home ]]; then cwd="$home"; else cwd=/tmp; fi
  echo "case: $label"

  (cd "$cwd" && HOME="$home" bash "$REPO/setup-stow.sh" ${mode:+"$mode"}) > "$home/.out" 2>&1 \
    || { fail "exit nonzero"; tail -5 "$home/.out" >&2; }

  if [[ "$mode" == -n ]]; then
    [[ ! -e "$home/.zshrc" ]] || fail "dry run created .zshrc"
  else
    assert_link_into_repo "$home" .zshrc
    assert_link_into_repo "$home" .config/herdr-app/keys.json
    assert_link_into_repo "$home" .config/herdr-app/settings.json
    assert_link_into_repo "$home" .claude/keybindings.json
    assert_link_into_repo "$home" .config/herdr/config.toml
    [[ ! -e "$home/.config/herdr/plugins.json" && ! -e "$home/.config/herdr/.plugins.lock" ]] || fail "generated herdr plugin files were linked"
    [[ -d "$home/.config/herdr" && ! -L "$home/.config/herdr" ]] || fail ".config/herdr is not a real directory"
    [[ "$(stat -f %Lp "$home/.ssh" 2>/dev/null || echo missing)" == 700 ]] || fail ".ssh mode is not 700"
  fi
  rm -rf "$home"
}

run_dry_run_side_effects_case() {
  local mode=$1 home mode_of
  home="$(mktemp -d)"
  echo "case: $mode leaves existing dirs untouched"
  mkdir -m 755 "$home/.ssh" "$home/.gnupg"
  chmod 755 "$home/.ssh" "$home/.gnupg"
  (cd "$home" && HOME="$home" bash "$REPO/setup-stow.sh" "$mode") > "$home/.out" 2>&1 \
    || { fail "exit nonzero"; tail -5 "$home/.out" >&2; }
  for d in .ssh .gnupg; do
    mode_of="$(stat -f %Lp "$home/$d")"
    [[ "$mode_of" == 755 ]] || fail "$mode changed $d to $mode_of"
  done
  created="$(find "$home" -mindepth 1 -not -name .out -not -path "$home/.ssh" -not -path "$home/.gnupg" | head -3)"
  [[ -z "$created" ]] || fail "$mode created: $created"
  rm -rf "$home"
}

run_herdr_runtime_files_case() {
  local src home linked
  src="$(mktemp -d)"
  home="$(mktemp -d)"
  echo "case: only herdr config.toml is linked beside herdr runtime files"
  rsync -a --exclude .git "$REPO/" "$src/"
  touch "$src/config/herdr/plugins.json" "$src/config/herdr/.plugins.lock" \
    "$src/config/herdr/session.json" "$src/config/herdr/herdr.log"
  ln -s /nonexistent/herdr.sock "$src/config/herdr/herdr.sock"
  (cd "$home" && HOME="$home" bash "$src/setup-stow.sh") > "$home/.out" 2>&1 \
    || { fail "exit nonzero"; tail -5 "$home/.out" >&2; }
  linked="$(ls -A "$home/.config/herdr" 2>/dev/null | tr '\n' ' ')"
  [[ "$linked" == "config.toml " ]] || fail ".config/herdr holds: ${linked:-nothing}"
  [[ -L "$home/.config/herdr/config.toml" ]] || fail ".config/herdr/config.toml is not a symlink"
  rm -rf "$src" "$home"
}

run_case "dry-run from HOME" home -n
run_case "dry-run from /tmp" tmp -n
run_case "real run from HOME" home ""
run_case "real run from /tmp" tmp ""
run_dry_run_side_effects_case -n
run_dry_run_side_effects_case -D
run_herdr_runtime_files_case

if (( failures > 0 )); then
  echo "$failures failure(s)" >&2
  exit 1
fi
echo PASS
