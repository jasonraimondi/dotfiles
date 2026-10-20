---
name: notebook
description: Notebook filing, in the vault at $AI_NOTEBOOK_PATH (default ~/Notebook). Use when writing a working doc (research, plan, review, handoff, prototype, scratch output), looking up prior work by ticket or topic, or linting the vault.
---

# Notebook

The notebook is a vault for working documents, plus a wiki that compounds them. Dated notes are the record: written once, filed by kind, named by timestamp. Wiki pages are the synthesis: one living page per ticket or topic, revised as notes land. A new session reads the page, not the pile.

## Path

Resolve the vault root once per task:

```sh
NOTEBOOK="${AI_NOTEBOOK_PATH:-$HOME/Notebook}"
```

`AI_NOTEBOOK_PATH` overrides the default `~/Notebook`. When the root is missing, create it with the eight dirs below: `mkdir -p "$NOTEBOOK"/{research,plans,decisions,reviews,prototypes,handoff,drafts,wiki}`. Every path in this skill is relative to `$NOTEBOOK`.

Durable project docs belong in the repo and follow their own skill or convention: `GLOSSARY.md`, ADRs, `README`, `AGENTS.md`, `CLAUDE.md`, skills. Skills such as domain-modeling own their output paths.

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
| `wiki/` | One living page per ticket or topic: the current synthesis of its notes. See Wiki |

The eight top-level dirs are closed. A doc that fits none goes in `drafts/`.

## Naming

- Timestamp: run `date +%Y-%m-%d-%H%M`. Read it from the command, every time.
- Note: `YYYY-MM-DD-HHMM-short-description.md`, lowercase kebab-case, ticket id first when there is one (`2026-09-29-2240-eng-1006-stuck-jobs.md`).
- Artifact (json, txt, sh, log, patch, sql, dump): lives in a folder `YYYY-MM-DD-HHMM-topic/`, beside the note that produced it. Reuse the topic's existing folder when one exists. Files keep their own names inside it.
- Wiki page: `wiki/<ticket-or-topic>.md`, kebab-case, ticket id first when there is one (`wiki/eng-1006-stuck-jobs.md`). No timestamp: the page is revised in place, never re-filed.

## Writing

1. Pick the dir from the table, then run `date` for the stamp.
2. Search first (see Reading). A note on the same ticket or topic links the earlier notes and is folded into the wiki page; the earlier notes stay as written.
3. Link other notes with a wikilink on the stem, `[[2026-09-29-2240-eng-1006-stuck-jobs]]`, and artifacts with a vault-relative path, `research/2026-08-11-1643-eng-1006/audit.txt`.
4. Reference specs, PRs, and issues by URL or path. Keep their content out of the note.
5. Redact keys, passwords, and personal data before saving.
6. Fold the note into its wiki page (see Wiki).

## Wiki

A wiki page is the agent-maintained synthesis of every note on a ticket or topic. The dated notes are its sources: the page cites them and is rewritten as they accumulate. It is the one place a claim about the topic is kept current.

A page exists once a ticket or topic has two notes. Create it from the notes on hand. After that, every new note on the topic is folded in: claims revised, superseded claims replaced, the note added to Sources.

Sections, in order:

- **State**: what is known now, each claim followed by the wikilink of the note that backs it.
- **Decisions**: what was decided and why, newest first.
- **Open**: unanswered questions and threads not yet picked up.
- **Sources**: a wikilink per note on the topic, newest first, one line each.

`index.md` at the vault root lists every wiki page, one line each: `- [[eng-1006-stuck-jobs]] — stuck jobs in the queue worker; root cause found, remediation pending`. Add the line when the page is created and revise it when the topic's state shifts.

A lookup that synthesizes several notes to answer a question is itself a finding: write it into the wiki page, so the next session reads it there instead of rebuilding it.

## Reading

Read down the ladder: `index.md`, then the wiki page, then the notes it cites. Filenames sort chronologically, so `ls "$NOTEBOOK/handoff" | tail` is the latest handoff and `ls "$NOTEBOOK/research" | tail` the latest research.

- Ticket or topic: `index.md` first, then its wiki page. When there is no page: `grep -rli "eng-1006" "$NOTEBOOK" --include='*.md'`, and when that turns up two or more notes, create the page before going on.
- Continuing work: the wiki page's Open and Decisions, then the newest matching note in `handoff/`, then its links.
- Obsidian's index skips `prototypes/`, `node_modules/`, and raw audit output, so search those with grep.

## Lint

On request, health-check the vault and fix what you find:

- Tickets or topics with two or more notes and no wiki page.
- Wiki pages whose Sources lag the notes on disk: grep the ticket id, diff against Sources, fold in what is missing.
- State claims superseded or contradicted by a newer note or by another wiki page.
- Open questions a later note has answered.
- Wiki pages missing from `index.md`, and index lines whose page is gone.

Report each page touched and what changed.

## Vault hygiene

Dependencies stay out: a prototype needing `pnpm install` runs from its repo or a scratch dir, with only its scripts and results saved here. Large raw dumps go in a dated folder, never loose in a dir or inline in a note.
