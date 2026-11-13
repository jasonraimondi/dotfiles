#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" && pwd)/git-cleanup"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() {
  echo "FAIL: $1" >&2
  echo "$output" >&2
  exit 1
}

new_repo() {
  rm -rf "$tmp/origin.git" "$tmp/work"
  git init --quiet --bare "$tmp/origin.git"
  git clone --quiet "$tmp/origin.git" "$tmp/work" 2>/dev/null
  cd "$tmp/work"
  git config user.email test@example.com
  git config user.name test
  git config commit.gpgsign false
  git commit --quiet --allow-empty -m init
  git push --quiet origin HEAD
}

run_cleanup() {
  status=0
  output="$(printf 'n' | bash "$script" 2>&1)" || status=$?
}

new_repo
run_cleanup
[ "$status" -eq 0 ] || fail "exited $status with nothing to delete"
echo "PASS: exits 0 with nothing to delete"

new_repo
git push --quiet origin HEAD:refs/heads/'('
git fetch --quiet
run_cleanup
[ "$status" -eq 0 ] || fail "exited $status with a remote branch named '('"
[[ $output != *"grep:"* ]] || fail "grep error surfaced for a remote branch named '('"
echo "PASS: remote branch names are not treated as regex"

new_repo
git push --quiet origin HEAD:refs/heads/axb HEAD:refs/heads/a.b
git fetch --quiet
git branch --quiet --track axb origin/axb
git push --quiet origin :axb
git fetch --quiet --prune
run_cleanup
[[ $output == *"  - axb"* ]] || fail "stale branch 'axb' not listed while remote has 'a.b'"
echo "PASS: stale branch is found despite a regex-like remote name"
