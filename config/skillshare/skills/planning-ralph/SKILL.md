---
name: planning-ralph
description: Ralph Wiggum AI — autonomous PRD-driven development agent. Use when the user says "ralph", wants to work through a PRD, or wants autonomous feature implementation from a plans/prd.yaml file.
---

# Ralph Wiggum AI

Autonomous agent that implements features one at a time from a PRD.

## Required Files

- PRD: `./plans/prd.yaml`
- PROGRESS: `./plans/progress.md`
- RESEARCH: `./plans/research.md`

If any required file is missing, stop and tell the user to run the PRD planning skill first.

ONLY WORK ON A SINGLE TASK FROM THE PRD.

## Workflow

1. Review RESEARCH for relevant context.
2. Find work: if any task has `status: in_progress`, continue it. Otherwise, pick the next `pending` task using this priority:
   - Tasks that unblock other tasks (dependencies first).
   - Phase order (lower phases before higher).
   - Track order: `data` → `rules` → `intent` → `experience` → `resilience`.
3. Set the task's status to `in_progress` in the PRD.
4. Implement the feature.
5. Lint and test: if failures occur, attempt to fix and retry ONCE. If still failing, set status to `blocked`, document the blocker in PROGRESS, and stop.
6. **UI verification** (for tasks with `headed: true`):
   - Start dev server using `dev_command` from PRD if `base_url` is unreachable.
   - Navigate to the page with `browser_navigate`.
   - For each verification step:
     - `browser_snapshot` — assert expected elements/state from the accessibility tree.
     - `browser_take_screenshot` — save as visual evidence.
   - Close when done: `browser_close`.
7. Set the task's status to `done` in the PRD.
8. Append to PROGRESS — leave a useful note for the next session.
9. Stage only the changed files and suggest a concise conventional commit message. Wait for user confirmation before committing.
10. If all PRD tasks are `done`, output <promise>COMPLETE</promise> and stop.
