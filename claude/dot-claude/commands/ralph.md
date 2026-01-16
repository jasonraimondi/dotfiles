---
description: Ralph Wiggum AI using PRD
model: claude-opus-4-5
---

Use files: 
- PRD ./@plans/prd.yaml 
- PROGRESS ./@plans/progress.md
- RESEARCH ./@plans/research.md

ONLY WORK ON A SINGLE FEATURE FROM THE PRD

1. Review RESEARCH
2. If any work is in_progress: true, continue, otherwise find the highest-priority feature to work on and work only on that feature. This should be the one YOU decide has the highest priority - not necessarily the first in the list.
3. Check that the lint and tests pass.
4. Update the PRD with the work that was done.
5. Append to the PROGRESS file. Use this to leave a note for the next person working in the codebase.
6. Make a git commit with that feature including only the files changed. Use a concise conventional commit message.
7. If, while implementing the feature, you notice the PRD is complete, output <promise>COMPLETE</promise> and stop.
