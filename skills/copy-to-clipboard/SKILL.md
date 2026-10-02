---
name: copy-to-clipboard
description: Pipe the response's prose to the macOS clipboard via `pbcopy` so the user can paste it directly. Use when the user asks to copy the response or runs /copy. macOS only.
---

## What to copy

The final user-facing prose for this turn — what the user would otherwise read in the chat. Skip tool output, diffs, status updates, and code fences that exist only to display content in chat. If the requested output *is* a snippet, copy the snippet's contents **without** the surrounding fences.

## How

One Bash call. Single-quoted heredoc with a random 6-char sentinel:

```bash
pbcopy <<'CLIP_a93b2f'
…content…
CLIP_a93b2f
```

The single quotes disable expansion, so `$`, backticks, backslashes, and newlines pass through literally. Pick a fresh sentinel each call; collision with content is the only failure mode and is negligible for normal prose.

Fallback (only if content might literally contain your sentinel — e.g. you're copying a doc *about* heredocs): Write to `/tmp/clip.txt`, then `pbcopy < /tmp/clip.txt`. No `rm` — `/tmp` cleans itself and the chained command can trip the harness into backgrounding.

For a short single-line string, `printf '%s' '<text>' | pbcopy` is fine.

## After

Acknowledge in one short line (e.g., `Copied.`) and stop — do not reprint the content; the user already has it. If `command -v pbcopy` finds nothing, say so and skip the copy. Don't try to install a clipboard tool.
