# Project-local pi extensions

## ask-user-question.ts

Claude-style AskUserQuestion equivalent.

### Tool
- `AskUserQuestion`

### Input shape
```json
{
  "questions": [
    {
      "question": "...",
      "header": "...",
      "options": [{ "label": "...", "description": "..." }],
      "multiSelect": false
    }
  ]
}
```

### Implemented feature set
- Multiple questions per call (`questions[]`)
- Per-question `header`
- Per-option `label` + `description`
- Per-question `multiSelect`
- Built-in custom typed answers (even when options are provided)
- Claude-style tool result summary text
- Structured `details` payload with `questions`, `answers`, `cancelled`

### Load
```bash
pi -e ai/pi/extensions/ask-user-question.ts
```

## clean-plan-mode.ts

Strict plan mode with hard read-only enforcement.

### Commands
- `/plan` - toggle plan mode
- `/plan-on` - enable plan mode
- `/plan-off` - disable plan mode
- `Ctrl+Alt+P` - toggle shortcut

### CLI
- `pi --plan` starts in plan mode

### Behavior in plan mode
- Active tools are restricted to: `read`, `grep`, `find`, `ls`
- Any other tool call is blocked (`edit`, `write`, `bash`, custom tools, etc.)
- Agent is instructed to analyze and produce a plan only
