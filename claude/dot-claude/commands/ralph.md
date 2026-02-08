---
description: Ralph Wiggum AI using PRD
model: claude-opus-4-6
---

Use files:
- PRD ./plans/prd.yaml
- PROGRESS ./plans/progress.md
- RESEARCH ./plans/research.md

ONLY WORK ON A SINGLE FEATURE FROM THE PRD.

## Workflow

1. Review RESEARCH for relevant context.
2. Find work: if any task has `status: in_progress`, continue it. Otherwise, pick the highest-priority `pending` task — prioritize by YOUR judgment, not list order.
3. Set the task's status to `in_progress` in the PRD.
4. Implement the feature.
5. Lint and test: if failures occur, attempt to fix and retry ONCE. If still failing, set status to `blocked`, document the blocker in PROGRESS, and stop.
6. **UI verification** (auto-triggered for `category: ui` tasks):
   - Start dev server using `dev_command` from PRD if `base_url` is unreachable
   - Open the page: `agent-browser open <base_url><path>` (add `--headed` if task has `headed: true`)
   - For each verification step:
     - `agent-browser snapshot` — assert expected elements/state from the accessibility tree
     - `agent-browser screenshot` — save to `plans/screenshots/<task-slug>.png` as visual evidence
   - Close when done: `agent-browser close`
7. Set the task's status to `done` in the PRD.
8. Append to PROGRESS — leave a useful note for the next session.
9. Commit only the changed files with a concise conventional commit message.
10. If all PRD tasks are `done`, output <promise>COMPLETE</promise> and stop.
