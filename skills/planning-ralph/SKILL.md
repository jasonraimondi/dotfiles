---
name: planning-ralph
description: Ralph Wiggum AI — autonomous PRD-driven development agent. Use when the user says "ralph", wants to work through issues, or wants autonomous feature implementation from a plans/ directory.
---

# Ralph Wiggum AI

Autonomous agent that implements issues one at a time from a PRD project.

## Arguments

- `forever` — loop through all remaining issues until the project is complete instead of stopping after one.
- `{slug}` — project slug. If omitted and only one project exists in `./plans/`, use it. Otherwise, ask.

## Required files

- PRD: `./plans/{slug}/prd.yaml`
- Issues: `./plans/{slug}/issues/*.yaml`

If the PRD or issues directory is missing, stop and tell the user to run `/planning-write-a-prd` and `/planning-prd-to-issues` first.

## Optional files

- `./plans/{slug}/progress.md` — session log. Created on first run if missing; appended after each completed issue.
- `./plans/{slug}/research.md` — background context. Read if present.

## Mode

- **Default** (no `forever`): complete one issue, then stop.
- **`forever`**: loop back to step 2 after each successful commit. Stop when all issues are `done`, an issue is `blocked`, or commit fails.

## Workflow

1. Read PRD, scan all issue files, and read progress.md/research.md if they exist.
2. **Find work**: if any issue has `status: in-progress`, continue it. Otherwise, pick the next `todo` issue by priority:
   - Issues that unblock others (`blocking` field is non-empty).
   - Track order: `data` → `rules` → `intent` → `experience` → `resilience`.
   - Lower issue ID breaks ties.
3. Set the issue's `status: in-progress` and `updated` date.
4. Implement following the issue's `steps` in order.
   - If `tdd: true`: use the `testing-tdd` skill — RED→GREEN for each step.
5. Lint and test. On failure: fix and retry ONCE. If still failing, set `status: blocked`, document the blocker in progress.md, and stop.
6. **UI verification** (issues with `headed: true`):
   - Start dev server if needed (check PRD for `dev_command` / `base_url`).
   - Use `tooling-agent-browser` skill to navigate, snapshot, and verify each visual step.
   - Close when done: `agent-browser close`.
7. Set the issue's `status: done` and `updated` date.
8. Append to `./plans/{slug}/progress.md` — one useful note for the next session.
9. Stage only changed files and commit with a concise conventional commit message.
   - Pre-commit hook failure: fix, re-stage, retry.
   - Commit denied or unable to proceed: **halt immediately** — do not continue.
10. If all issues are `done`, output <promise>COMPLETE</promise> and stop.
11. **Forever mode only**: loop back to step 2.
