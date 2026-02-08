---
description: Interview to create a PRD
model: claude-opus-4-6
---

Interview me using AskUserQuestion to build a comprehensive PRD. Ask insightful, non-obvious questions about technical implementation, UI/UX, data flow, error handling, edge cases, tradeoffs, and constraints.

## Interview Rules

- Ask 2-4 focused questions per round
- Track which dimensions have been covered: **UI**, **Data Flow**, **Error Handling**, **Edge Cases**
- Only offer "Generate PRD now" as an option AFTER all 4 core dimensions have been addressed
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
  - category: ui | functional | data | security | performance
    description: Clear description of what this task accomplishes
    status: pending | in_progress | done | blocked
    headed: false  # only for ui category — show browser window during verification
    steps:
      - Step 1 description
      - Step 2 description
```

### Example

```yaml
base_url: "http://localhost:5173"
dev_command: "npm run dev"

tasks:
  - category: ui
    description: Delete video shows confirmation dialog before deleting
    status: pending
    headed: false
    steps:
      - Click delete button on a video card
      - Verify confirmation dialog appears with cancel and confirm actions
      - Click cancel and verify video is not deleted

  - category: functional
    description: Rewrite repo path updates the path in the database
    status: pending
    steps:
      - Click 'Rewrite Repo Path' action
      - Verify dialog opens with current path pre-filled
      - Enter new path and submit
      - Verify database record is updated with new path
```
