---
name: planning-ralph
description: Ralph Wiggum AI — autonomous PRD-driven development agent. Use when the user says "ralph", wants to work through a PRD, or wants autonomous feature implementation from a plans/prd.yaml file.
---

# Ralph Wiggum AI

Autonomous agent that implements features one at a time from a PRD.

## Arguments

- `forever` — loop through all remaining tasks until the PRD is complete instead of stopping after one task.

## Required Files

- PRD: `./plans/prd.yaml`
- PROGRESS: `./plans/progress.md`
- RESEARCH: `./plans/research.md`

If any required file is missing, stop and tell the user to run the PRD planning skill first.

## Mode

- **Default** (no arguments): work on a single task, then stop.
- **`forever`**: loop back to step 2 after each successful commit. Stop only when all tasks are `done`, a task is `blocked`, or you are unable to commit.

## Workflow

1. Review RESEARCH for relevant context.
2. Find work: if any task has `status: in_progress`, continue it. Otherwise, pick the next `pending` task using this priority:
   - Tasks that unblock other tasks (dependencies first).
   - Phase order (lower phases before higher).
   - Track order: `data` → `rules` → `intent` → `experience` → `resilience`.
3. Set the task's status to `in_progress` in the PRD.
4. Implement the feature. If the task has `tdd: true`, follow the RED→GREEN vertical slices in order.
5. Lint and test: if failures occur, attempt to fix and retry ONCE. If still failing, set status to `blocked`, document the blocker in PROGRESS, and stop.
6. **UI verification** (for tasks with `headed: true`):
   - Start dev server using `dev_command` from PRD if `base_url` is unreachable.
   - Use `tooling-agent-browser` skill (agent-browser CLI) to navigate, snapshot, and verify each step.
   - Close when done: `agent-browser close`.
7. Set the task's status to `done` in the PRD.
8. Append to PROGRESS — leave a useful note for the next session.
9. Stage only the changed files and commit with a concise conventional commit message.
   - If a pre-commit hook fails: fix the issue, re-stage, and retry the commit.
   - If the commit is denied by the user or you are otherwise unable to commit (permission rejected, hook you cannot fix): **halt immediately** — do not continue to the next task.
10. If all PRD tasks are `done`, output <promise>COMPLETE</promise> and stop.
11. **Forever mode only**: if argument is `forever` and commit succeeded, loop back to step 2.
