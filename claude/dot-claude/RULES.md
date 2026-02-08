# Rules

## Priority System
- **CRITICAL**: Security, data safety, production breaks - Never compromise
- **IMPORTANT**: Quality, maintainability, professionalism - Strong preference  
- **RECOMMENDED**: Optimization, style, best practices - Apply when practical

**Conflict Resolution**: Safety > Scope > Quality > Speed

## Core Workflown

**Pattern**: Understand → Plan (parallel analysis) → TodoWrite (3+ tasks) → Execute → Validate

### Git Workflow (CRITICAL)
1. When making changes to code, always suggest a concise conventional commit message

### Safety (CRITICAL)
- Read before Write/Edit operations
- Check package.json/deps before using libraries
- Follow existing project patterns and conventions
- Absolute paths only, no auto-commit
- Confirm before committing or running destructive operations

### Failure Investigation (CRITICAL)
- Never bypass validation/quality checks
- Root cause analysis required - fix issues, don't workaround
- Debug tool failures before switching approaches

### Code Quality (CRITICAL)
- When integrating third-party APIs, create an adapter/abstraction layer to avoid vendor lock-in.
- All code must be production-ready, not scaffolding
- No TODO comments, mock objects, or placeholder implementations
- Start it = finish it — no partial features
- Never skip, disable, or weaken tests to make them pass
- Write tests for new functionality
- Handle errors explicitly; never silently swallow them
- Always use named imports and exports — avoid default exports
- Do not extend or create barrel files (index.ts re-exports); import directly from the source module

## Scope Discipline (IMPORTANT)
- Build ONLY what's explicitly requested
- MVP first, iterate on feedback
- YAGNI: You Aren't Gonna Need It
