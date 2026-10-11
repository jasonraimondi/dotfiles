---
name: atuin
description: Search Jason's shell history with atuin. Use when asked how he ran, deployed, or set up something before, what he ran in a directory or on a day, or to recover a lost command; or before guessing at an undocumented project command (deploy, seed, release, one-off script).
---

# Atuin

Atuin records every interactive shell command in a local SQLite database with its directory, time, duration, host, and exit code. Treat it as the lab notebook: the most recent successful run of a command is better evidence than any guess or README.

## Steps

1. **Query** with the base command, adding filters from the table below:

   ```bash
   atuin search --search-mode fulltext --limit 20 \
     --format '{time}\t{exit}\t{duration}\t{directory}\t{command}' WORDS
   ```

2. **Widen** when results are thin: drop the directory filter, swap in fewer or shorter words, raise `--limit`. Narrow when they're noisy: add `--exit 0`, a date bound, or more words.
3. **Answer** with the command verbatim plus its time, directory, and exit code. Prefer the most recent exit-0 run; say when the only matches failed. Done when you've cited a run, or listed the searches that came up empty.

## Filters

| Want | Flag |
|---|---|
| exactly one directory | `--cwd DIR` (exact match; subdirectories excluded) |
| anywhere in the current git repo | `--filter-mode workspace`, run from inside the repo |
| a time window | `--after '3 days ago'`, `--before 2026-01-01` (natural language and ISO dates both parse) |
| runs that worked | `--exit 0` |
| runs that failed | `--exclude-exit 0` |
| oldest matches instead of newest | `-r` |
| commands that start with the words | `--search-mode prefix` |
| most-run commands | `atuin stats --count 20 [PERIOD]` |

## Reading results

- **Fulltext, always.** The configured default is fuzzy, where `git` matches `STAGE=bill devbox stop`. Fuzzy results are noise for an agent.
- **Order.** Without `-r` you get the newest N matches, printed oldest first: the latest run is the last line.
- **Exit `-1`** means no end was recorded: a dev server killed with Ctrl-C, a closed shell, or a command still running (the current `claude` session shows as `-1`). `--exit 0` hides all of these, so drop it when hunting for a long-running command.
- **Multiline commands** (pasted blocks) span several output lines. Add `--print0` when piping results into another tool.
- **Paste junk** shows up too: a prompt pasted with its command (`~/C/a/app ❯❯❯ git push`, exit 127). Skip it.
- **Worktrees.** Jason works in Herdr worktrees under `~/.herdr/worktrees/<org>/<name>/…`, so one repo's history is spread across many directories that neither `--cwd` nor `workspace` joins. Search without a directory filter and read the directory column.
- **Secrets.** History can hold tokens and passwords inline. Quote the command's shape and replace the secret with a placeholder.

## Read-only

This skill only reads. `--delete`, `--delete-it-all`, `history prune`, and `history dedup` destroy history and any captured output irreversibly; run them only when Jason asks for that exact deletion.

## Optional features

Both change config, so offer them; run only on a yes.

- **Agent attribution.** `atuin hook install claude-code` adds hooks to `~/.claude/settings.json` so the Bash commands an agent runs land in history tagged with its name. Until then every entry is Jason's own, and agent commands are absent. Once installed: `--author '$all-user'` for his commands, `--author '$all-agent'` or `--author claude-code` for agents'.
- **Output search.** `atuin output search WORDS` searches what commands printed, but only after `atuin config enable output-capture` (starts the daemon and pty-proxy; needs a new shell). Before that it errors with `output capture is disabled`.
