---
name: planning-review-prd
description: Review PRD plans as a principal software engineer. Analyzes task quality, missing edge cases, phase ordering, track coverage, and architectural gaps. Auto-fixes obvious issues (missing tdd/headed flags, key ordering, weak verbs) and asks clarifying questions for non-obvious concerns. Use when user says "review my plan", "review the PRD", "check my tasks", or wants feedback on plans/ output.
---

# PRD Plan Review

Review plans/ output as a principal software engineer. Auto-fix mechanical issues, surface architectural gaps, ask about non-obvious concerns.

## Execution checklist

1. **Load all plan files** — read `plans/prd.yaml`, `plans/prd/shared.yaml`, every `phase-*.yaml`, `plans/progress.md`, and `plans/research.md` + research docs if they exist.
2. **Load project context** — scan codebase for existing patterns: routes, schema, services, auth, error handling. This grounds the review in reality, not theory.
3. **Run auto-fix pass** — apply mechanical fixes directly (see auto-fix rules below). Report what changed.
4. **Run review pass** — evaluate each dimension in the rubric. Collect findings as `fix` (actionable, concrete) or `question` (needs user input).
5. **Apply fixes** — write corrected plan files.
6. **Ask questions** — use `AskUserQuestion` to surface non-obvious concerns. Group related questions. 2-4 questions per round, continue until resolved.
7. **Final summary** — list all changes made and any remaining open items added to `shared.yaml`.

## Auto-fix rules (apply without asking)

These are mechanical violations of the planning-prd spec. Fix silently and report.

| Issue | Fix |
|-------|-----|
| `rules` or `data` task missing `tdd: true` | Add `tdd: true` |
| `experience` task missing `headed: true` | Add `headed: true` |
| `resilience` task with testable behavior missing `tdd: true` | Add `tdd: true` |
| Wrong key order (not `track → description → status → tdd/headed → steps`) | Reorder keys |
| `description` doesn't start with strong verb | Rewrite to start with: Build, Implement, Configure, Create, Define, Write, Handle, Set up |
| `headed` steps without visual verification target | Append `— verify <observable outcome>` |
| TDD steps not in RED→GREEN vertical pairs | Restructure into paired slices |
| Horizontal test slicing (all RED then all GREEN) | Interleave into vertical RED→GREEN pairs |
| TOC checkbox status doesn't match phase task statuses | Sync TOC checkboxes |
| `intent` task with API/service behavior missing `tdd: true` | Add `tdd: true` |

## Review rubric

Evaluate every phase against these dimensions. Only raise issues that matter — skip nitpicks.

### 1) Task decomposition

- **One outcome per task** — flag tasks that combine unrelated work (e.g., "Build UI and implement auth logic").
- **Right granularity** — too coarse (>8 steps) or too fine (1-2 trivial steps) are both problems.
- **No orphan work** — every task's output is consumed by a later task or is a deliverable itself.

### 2) Track coverage

For each phase, check if relevant tracks are represented:

- Feature touching data? → needs `data` track tasks.
- Feature with authorization/validation? → needs `rules` track.
- Feature with UI? → needs `experience` track.
- Feature with external dependencies or failure modes? → needs `resilience` track.
- Missing tracks are the highest-signal finding. Flag them.

### 3) Edge cases and failure paths

- **Every user-facing action** should have success AND failure steps.
- **Permission boundaries** — what happens when unauthorized user hits this?
- **Empty/loading/error states** in experience tasks.
- **Race conditions** — concurrent mutations on same entity?
- **Cascade effects** — what breaks downstream when this entity is deleted?

### 4) Phase ordering and dependencies

- **No forward references** — phase N should not depend on work defined in phase N+1.
- **Data before logic before UI** — schema and services should precede the UI that consumes them (within same phase is fine if steps are ordered).
- **Critical path first** — highest-risk or most-uncertain work should be in earlier phases.

### 5) Step quality

- Every step follows `Target — required behavior` pattern.
- Steps include **location context** (route, file path, service name).
- TDD steps specify the assertion, not just "test it works".
- No vague language: "handle errors appropriately", "set up properly", "add necessary validation".

### 6) shared.yaml completeness

- `global_constraints` — are there implied constraints not captured?
- `decisions` — are there choices made during the interview that aren't recorded?
- `assumptions` — are there things the plan depends on that haven't been verified?
- `open_questions` — do any remain that could block implementation?

### 7) Architectural concerns

- **Vendor lock-in** — direct dependency on third-party API without adapter layer?
- **Missing migrations** — schema changes without migration steps?
- **Security gaps** — input validation, auth checks, secret handling, rate limiting?
- **Performance at scale** — queries that scan full tables, N+1 patterns, missing pagination?

## AskUserQuestion guidelines

Only ask about things you **cannot resolve from the codebase or plan itself**.

Good questions:
- "Phase 2 adds SSO but no rate limiting on login attempts. Should I add a resilience task for brute-force protection, or is this handled by an existing middleware?"
- "The plan creates JIT user accounts on SSO callback but doesn't address what happens if the user's email changes in the IdP. Should we track IdP subject ID separately?"
- "Phase 3 has domain verification but no task for re-verification. Should domains expire or is one-time verification sufficient?"

Bad questions (never ask these):
- "Do you want me to review the plan?" (you're already doing it)
- "Should tasks have tests?" (follow the spec)
- "Is the key ordering correct?" (just fix it)
- "Do you want me to add `tdd: true`?" (just add it)

## Output format

After all fixes and questions are resolved:

```
## Review summary

### Auto-fixed (N issues)
- [list of mechanical fixes applied]

### Findings (N issues)
- [actionable findings with specific task/phase references]

### Questions resolved
- [questions asked and decisions made]

### Changes to shared.yaml
- [new decisions, assumptions, or open questions added]
```

## Anti-patterns

- Reviewing style/formatting over substance
- Suggesting refactors the planning-prd spec doesn't support
- Adding tasks for hypothetical future requirements
- Rewriting the entire plan instead of targeted fixes
- Asking about things that are obvious from the codebase
- Proposing architectural changes that contradict recorded decisions
