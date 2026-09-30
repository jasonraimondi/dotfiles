---
name: notebook
description: Notebook filing, in the vault at $AI_NOTEBOOK_PATH (default ~/Notebook). Use when writing a working doc (research, plan, review, handoff, prototype, scratch output) or looking up prior work by ticket or topic.
---

# Notebook

The notebook is a vault for working documents. Every working doc lands here, filed by kind, named by timestamp.

## Path

Resolve the vault root once per task:

```sh
NOTEBOOK="${AI_NOTEBOOK_PATH:-$HOME/Notebook}"
```

`AI_NOTEBOOK_PATH` overrides the default `~/Notebook`. When the root is missing, create it with the seven dirs below: `mkdir -p "$NOTEBOOK"/{research,plans,decisions,reviews,prototypes,handoff,drafts}`. Every path in this skill is relative to `$NOTEBOOK`.

Durable project docs belong in the repo and follow their own skill or convention: `CONTEXT.md`, ADRs, `README`, `AGENTS.md`, `CLAUDE.md`, skills. Skills such as domain-modeling own their output paths.

## Where it goes

| Dir | Holds |
|---|---|
| `research/` | Investigations and findings. `research/traces/` for command and API traces, `research/screenshots/` for captures |
| `plans/` | Plans. Multi-week efforts get a project folder, e.g. `plans/billing-shift/` |
| `decisions/` | Personal decision notes. `decisions/grills/` for grill sessions, `decisions/deploys/` for deploy notes |
| `reviews/` | Code and PR reviews. `reviews/reports/` for standalone HTML and CSV reports |
| `prototypes/` | Throwaway code and scripts |
| `handoff/` | Session handoffs, including Skill(handoff) output |
| `drafts/` | Unfinished writing, and the fallback when no other dir fits |

The seven top-level dirs are closed. A doc that fits none goes in `drafts/`.

## Naming

- Timestamp: run `date +%Y-%m-%d-%H%M`. Read it from the command, every time.
- Note: `YYYY-MM-DD-HHMM-short-description.md`, lowercase kebab-case, ticket id first when there is one (`2026-09-29-2240-eng-1006-stuck-jobs.md`).
- Artifact (json, txt, sh, log, patch, sql, dump): lives in a folder `YYYY-MM-DD-HHMM-topic/`, beside the note that produced it. Reuse the topic's existing folder when one exists. Files keep their own names inside it.

## Writing

1. Pick the dir from the table, then run `date` for the stamp.
2. Search first (see Reading). A note on the same ticket or topic gets extended or linked, not duplicated.
3. Link other notes with a wikilink on the stem, `[[2026-09-29-2240-eng-1006-stuck-jobs]]`, and artifacts with a vault-relative path, `research/2026-08-11-1643-eng-1006/audit.txt`.
4. Reference specs, PRs, and issues by URL or path. Keep their content out of the note.
5. Redact keys, passwords, and personal data before saving.

## Reading

Filenames sort chronologically, so `ls "$NOTEBOOK/handoff" | tail` is the latest handoff and `ls "$NOTEBOOK/research" | tail` the latest research.

- Ticket or topic: `grep -rli "eng-1006" "$NOTEBOOK" --include=*.md`
- Continuing work: start from the newest matching note in `handoff/`, then follow its links.
- Obsidian's index skips `prototypes/`, `node_modules/`, and raw audit output, so search those with grep.

## Vault hygiene

Dependencies stay out: a prototype needing `pnpm install` runs from its repo or a scratch dir, with only its scripts and results saved here. Large raw dumps go in a dated folder, never loose in a dir or inline in a note.
