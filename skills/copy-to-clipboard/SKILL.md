---
name: copy-to-clipboard
description: Pipe the response's prose to the macOS clipboard via `pbcopy` so the user can paste it directly. Use when the user says "copy to clipboard", "/copy", "pbcopy this", "put it on my clipboard", or otherwise asks for paste-ready output. macOS only.
---

## What to copy

The final user-facing prose for this turn — what the user would otherwise read in the chat. Skip tool output, diffs, status updates, and code fences that exist only to display content in chat. If the requested output *is* a snippet, copy the snippet's contents **without** the surrounding fences.

## How

Write the content to `/tmp/clip.txt` via the Write tool, then:

```bash
pbcopy < /tmp/clip.txt && rm /tmp/clip.txt
```

Going through a file avoids heredoc-delimiter collisions and quoting hazards with `$`, backticks, and embedded newlines. For a short single-line string, `printf '%s' '<text>' | pbcopy` is fine.

## After

Acknowledge in one short line (e.g., `Copied.`) and stop — do not reprint the content; the user already has it. If `command -v pbcopy` finds nothing, say so and skip the copy. Don't try to install a clipboard tool.
