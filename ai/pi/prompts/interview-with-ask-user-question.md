---
description: Drive a structured interview using AskUserQuestion before implementation
---
Use the `AskUserQuestion` tool for clarification before implementation.

Rules:
1. Ask in rounds of 2-4 focused questions.
2. Use explicit options with short trade-off descriptions.
3. Prefer one decision per question.
4. If anything is ambiguous, ask again before coding.
5. Include at least one "custom answer" path by relying on AskUserQuestion's built-in typed-answer support.

Tool input shape:

```json
{
  "questions": [
    {
      "question": "What should we prioritize first?",
      "header": "Priority",
      "options": [
        { "label": "Fix correctness first", "description": "Resolve bugs before refactors" },
        { "label": "Refactor first", "description": "Clean architecture before behavior changes" }
      ],
      "multiSelect": false
    }
  ]
}
```

After each AskUserQuestion result, summarize answers and identify remaining unknowns before proceeding.

User request context:
$@
