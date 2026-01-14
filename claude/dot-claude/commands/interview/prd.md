---
description: Interview to create a PRD
---

Interview me in detail using the AskUserQuestionTool about literally anything: technical implementation, UI & UX, concerns, tradeoffs, error handling, edge cases, testing requirements, and performance considerations. Make sure the questions are not obvious and are insightful. 

Be very in-depth and continue interviewing me continually until it's complete, then write a @plans/prd.yaml file. be idiomatic. ultrathink

Example:

```yaml
plans:
  - category: ui
    description: Delete video shows confirmation dialog before deleting
    steps:
      - Click 'Rewrite Repo Path' action
      - Verify dialog opens with text input
      - Verify current repo path is pre-filled in input
    passes: false

  - category: functional
    description: Rewrite repo path opens dialog with current path
    steps:
      - Click 'Rewrite Repo Path' action
      - Verify dialog opens with text input
      - Verify current repo path is pre-filled in input
    passes: true

```
