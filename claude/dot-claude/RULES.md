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
1. NEVER automatically commit to git
2. Suggest a conventional commit messages

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
- No enterprise features (auth, deployment, monitoring) unless asked
- YAGNI: You Aren't Gonna Need It

### File Organization
- **Claude docs**: `claudedocs/` (reports, analyses)
- **Tests**: `tests/`, `__tests__/`, or `test/`
- **Scripts**: `scripts/`, `tools/`, or `bin/`
- Think before creating - check existing patterns first

### Professional Standards
- No marketing language ("blazingly fast", "100% secure", "magnificent")
- No fake metrics or invented estimates
- Evidence-based claims only - say "untested" not "production-ready"
- Critical assessment with honest trade-offs

### Workspace Hygiene
- Remove temporary files after operations
- Clean artifacts, logs, debugging outputs before completion
- No leftover `temp/` directories or `debug.sh` files

## Recommended Rules

### Tool Optimization
- **Best tool selection**: MCP > Native > Basic
- **Parallel everything**: Independent ops run concurrently
- **Batch operations**: MultiEdit over multiple Edits
- **Agent delegation**: Use Task agents for complex multi-step ops

### Code Organization
- Follow language standards (camelCase JS, snake_case Python)
- Descriptive names for files, functions, variables
- Organize by feature/domain, not file type
- Match existing project conventions

### Planning Efficiency
- Identify parallelizable operations during planning
- Map dependencies clearly
- Estimate token usage and execution time
- Specify expected efficiency gains

## Quick Decision Trees

### File Operations
```
File operation?
├─ Writing/Editing? → Read first → Understand patterns → Edit
├─ Creating? → Check structure → Place appropriately
└─ Safety → Absolute paths → No auto-commit
```

### New Feature
```
Request?
├─ Scope clear? → No → Brainstorm first
├─ >3 steps? → TodoWrite required
├─ Check patterns & deps → Follow exactly
└─ Run tests before starting
```

### Tool Selection
```
├─ Multi-file edits → MultiEdit
├─ Complex analysis → Task agent
├─ Code search → Grep tool
├─ UI components → Magic MCP
└─ Documentation → Context7 MCP
```

## Detection Commands
- Wrong branch: `git branch` (should show feature branch)
- Skipped tests: `grep -r "skip\|disable\|TODO" tests/`
- Workspace pollution: Check for temp files, debug scripts in root
