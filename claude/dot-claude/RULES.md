# Claude Code Rules

## Priority System
- **CRITICAL**: Security, data safety, production breaks - Never compromise
- **IMPORTANT**: Quality, maintainability, professionalism - Strong preference  
- **RECOMMENDED**: Optimization, style, best practices - Apply when practical

**Conflict Resolution**: Safety > Scope > Quality > Speed

## Core Workflow
**Pattern**: Understand → Plan (parallel analysis) → TodoWrite (3+ tasks) → Execute → Validate

## Critical Rules

### Git Workflow (CRITICAL)
1. When making changes to code, always suggest a concise conventional commit message

### Safety (CRITICAL)
- Read before Write/Edit operations
- Check package.json/deps before using libraries
- Follow existing project patterns and conventions
- Absolute paths only, no auto-commit

### Failure Investigation (CRITICAL)
- Never skip or disable tests to achieve results
- Never bypass validation/quality checks
- Root cause analysis required - fix issues, don't workaround
- Debug tool failures before switching approaches

## Important Rules

### Implementation Completeness
- **Start it = Finish it** - no partial features
- No TODO comments, mock objects, or stub implementations
- All code must be production-ready, not scaffolding
- ✅ `function calc() { return price * tax; }`
- ❌ `function calc() { throw new Error("Not implemented"); }`

### Scope Discipline  
- Build ONLY what's explicitly requested
- MVP first, iterate on feedback
- YAGNI: You Aren't Gonna Need It
