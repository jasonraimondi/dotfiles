#!/usr/bin/env bash
set -euo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" && pwd)/git-cleanup"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git init --quiet --bare "$tmp/origin.git"
git clone --quiet "$tmp/origin.git" "$tmp/work" 2>/dev/null
cd "$tmp/work"
git config user.email test@example.com
git config user.name test
git config commit.gpgsign false
git commit --quiet --allow-empty -m init
git push --quiet origin HEAD

status=0
output="$(bash "$script" </dev/null 2>&1)" || status=$?

if [ "$status" -ne 0 ]; then
  echo "FAIL: git-cleanup exited $status with nothing to delete" >&2
  echo "$output" >&2
  exit 1
fi
echo "PASS: git-cleanup exits 0 with nothing to delete"
