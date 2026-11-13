#!/usr/bin/env bash
set -euo pipefail

[[ -n "${HC_TERMINAL_ID:-}" && -z "${HERDR_TAB_TITLE_CHILD:-}" ]] || exit 0
command -v herdr-app >/dev/null && command -v jq >/dev/null || exit 0

input=$(cat)
session_id=$(jq -r '.session_id // empty' <<<"$input")
prompt=$(jq -r '.prompt // empty' <<<"$input" | head -c 2000)
[[ -n "$session_id" && -n "$prompt" ]] || exit 0

marker_dir="${TMPDIR:-/tmp}/herdr-tab-title"
mkdir -p "$marker_dir"
marker="$marker_dir/$session_id"
[[ -e "$marker" ]] && exit 0
touch "$marker"

name_tab() {
  local tab_id tab_name title
  read -r tab_id tab_name < <(herdr-app ls | jq -r --arg t "$HC_TERMINAL_ID" '
    .spaces[].tabs[] | select(any(.terminals[]; .terminal == $t)) | "\(.id) \(.name)"')
  # Herdr's default tab name is its number; anything else was named on purpose.
  [[ -n "$tab_id" && "$tab_name" =~ ^[0-9]+$ ]] || return 0

  title=$(HERDR_TAB_TITLE_CHILD=1 claude -p \
    --model haiku \
    --no-session-persistence \
    --settings '{"disableAllHooks":true}' \
    "Name this coding task for a terminal tab in 2-4 lowercase words, 5 at most. Fewer is better. Reply with the name only, no quotes or punctuation. Task: $prompt" \
    </dev/null | head -n1 | tr -d '"`.' | cut -c1-40)
  [[ -n "$title" ]] || return 0

  herdr-app do tab.rename --id "$tab_id" --name "$title" >/dev/null
}

name_tab </dev/null >/dev/null 2>&1 &
disown
