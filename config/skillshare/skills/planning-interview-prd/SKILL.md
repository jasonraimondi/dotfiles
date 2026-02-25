---
name: planning-interview-prd
description: Interview to create a PRD. Use when the user wants to build a product requirements document, plan a feature, or says "interview" or "prd". Conducts a structured interview then outputs plans/prd.yaml.
---

# PRD Interview

Interview the user using AskUserQuestion to build a comprehensive PRD. Ask insightful, non-obvious questions — probe edges within each track rather than saving "edge cases" for a separate round.

## Tracks

Interview in two layers, product first then engineering:

### Product Layer (what)
- **Intent** — Who is this for, what problem does it solve, what does success look like, scope boundaries
- **Experience** — UI, flows, interactions, feedback, empty/loading/error states
- **Data** — Models, state, persistence, relationships, transformations

### Engineering Layer (how)
- **Rules** — Validation, auth, business logic, permissions, constraints
- **Resilience** — Failure modes, error states, degraded behavior, recovery

## Interview Rules

- Ask 2-4 focused questions per round
- Track coverage across all 5 tracks — show uncovered tracks as a reminder after each round
- Always include "Generate PRD now" as an option, but note which tracks are still uncovered
- When the user selects "Generate PRD now", stop interviewing and write the PRD immediately
- Never write code — only produce the PRD file

## Output

Write a `plans/prd.yaml` file.

### Schema

```yaml
# Top-level config (optional, for projects with UI)
base_url: "http://localhost:3000"
dev_command: "npm run dev"

tasks:
  - track: intent | experience | data | rules | resilience
    description: Clear description of what this task accomplishes
    status: pending | in_progress | done | blocked
    headed: false  # experience track only — show browser window during verification
    steps:
      - Step 1 description
      - Step 2 description
```

### Example

```yaml
base_url: "http://localhost:5173"
dev_command: "npm run dev"

tasks:
  - track: intent
    description: User can manage their video library without accidental deletions
    status: pending
    steps:
      - Verify delete flow requires explicit confirmation
      - Verify cancelled deletes leave data untouched

  - track: experience
    description: Delete video shows confirmation dialog before deleting
    status: pending
    headed: false
    steps:
      - Click delete button on a video card
      - Verify confirmation dialog appears with cancel and confirm actions
      - Click cancel and verify video is not deleted

  - track: data
    description: Rewrite repo path updates the path in the database
    status: pending
    steps:
      - Click 'Rewrite Repo Path' action
      - Verify dialog opens with current path pre-filled
      - Enter new path and submit
      - Verify database record is updated with new path

  - track: rules
    description: Only video owners can delete their own videos
    status: pending
    steps:
      - Attempt delete as video owner — verify success
      - Attempt delete as non-owner — verify 403 and video unchanged

  - track: resilience
    description: Delete handles server errors gracefully
    status: pending
    steps:
      - Simulate API failure during delete
      - Verify error toast shown to user
      - Verify video remains in list unchanged
```
