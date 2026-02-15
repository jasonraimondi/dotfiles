# Project-local pi extensions

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
