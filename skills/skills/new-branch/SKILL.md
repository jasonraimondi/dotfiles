---
name: new-branch
description: Create a new git branch named jason/{type}/{ticket-}{short-description} using conventional-commit types. Use when the user runs /new-branch or asks to start a new branch, or starts work that should happen on its own branch.
---

## Branch name format

```
jason/<type>/<ticket->< short-description>
```

- `jason/feat/int-123-add-oauth-login` — with a ticket
- `jason/fix/checkout-price-rounding` — without a ticket
- `jason/chore/bump-node-22`

## Picking the parts

**Type** — conventional-commit types, same judgment as a commit message: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `ci`, `build`. Infer from what the work is; a bug fix is `fix` even if it also cleans things up.

**Ticket** — include only if one exists in context: the user's message, a pasted Linear/Jira URL, or a referenced issue (pattern `[A-Z]+-\d+`). Lowercase it: `INT-123` → `int-123-`. No ticket → omit the segment entirely; never invent one.

**Short description** — 2–5 words, kebab-case, all lowercase, letters/digits/hyphens only. Describe the change, not the process: `add-oauth-login`, not `implementing-the-new-oauth-login-flow`.

If both type and description are obvious from context, don't ask — build the name. Only ask if the work itself is unclear.

## Creating the branch

```bash
git switch -c jason/feat/int-123-add-oauth-login
```

Branches from the current HEAD and carries any uncommitted changes with it — usually what's wanted (work already started, needs a branch). If the user asks to branch from main:

```bash
git switch -c jason/fix/checkout-price-rounding main
```

If the name already exists, `git switch -c` fails — pick a more specific description rather than appending `-2`.

## After

Confirm in one line with the branch name, e.g. `Created and switched to jason/feat/int-123-add-oauth-login.` Don't push or set upstream unless asked.
