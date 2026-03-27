---
name: planning-review-prd
description: Review a PRD and its issues as a principal software engineer. Checks track coverage, step quality, point limits, tdd/headed flags, missing edge cases, dependency ordering, and architectural gaps. Auto-fixes mechanical issues, asks about non-obvious concerns. Use when user says "review my plan", "review the PRD", "check my issues", or wants feedback on plans/ output.
---

# PRD Plan Review

Review a PRD and its issues as a principal software engineer. Auto-fix mechanical issues, surface architectural gaps, ask about non-obvious concerns.

## Execution checklist

1. **Load all plan files** — read `./plans/{slug}/prd.yaml` and all files in `./plans/{slug}/issues/`.
2. **Load project context** — scan codebase for existing patterns: routes, schema, services, auth, error handling. This grounds the review in reality, not theory.
3. **Run auto-fix pass** — apply mechanical fixes directly (see auto-fix rules below). Report what changed.
4. **Run review pass** — evaluate each dimension in the rubric. Collect findings as `fix` (actionable, concrete) or `question` (needs user input).
5. **Apply fixes** — write corrected issue and PRD files.
6. **Ask questions** — use `AskUserQuestion` to surface non-obvious concerns. Group related questions. 2-4 questions per round, continue until resolved.
7. **Final summary** — list all changes made and any remaining open items.

## Auto-fix rules (apply without asking)

These are mechanical violations of the issue schema spec. Fix silently and report.

| Issue | Fix |
|-------|-----|
| Missing `track` field | Infer from issue content and assign |
| `rules` or `data` issue missing `tdd: true` with testable behavior | Add `tdd: true` |
| `experience` issue missing `headed: true` | Add `headed: true` |
| `resilience` issue with testable behavior missing `tdd: true` | Add `tdd: true` |
| `intent` issue with API/service behavior missing `tdd: true` | Add `tdd: true` |
| `headed` steps without visual verification target | Append `— verify <observable outcome>` |
| Steps missing location context (no route, file, service, or component) | Add location context |
| Steps using vague language ("handle errors appropriately", "set up properly") | Rewrite with specific behavior |
| `blocked_by` / `blocking` out of sync across issues | Sync both directions |
| Points > 3 | Flag for split (cannot auto-fix — needs user input) |
| Missing `updated` date or stale date | Set to today |

## Review rubric

Evaluate every issue against these dimensions. Only raise issues that matter — skip nitpicks.

### 1) Issue decomposition

- **One outcome per issue** — flag issues that combine unrelated work (e.g., "Build UI and implement auth logic").
- **Right granularity** — max 3 points. Issues with too many steps (>6) or too few (1 trivial step) are both problems.
- **No orphan work** — every issue's output is consumed by a later issue or is a deliverable itself.
- **Vertical, not horizontal** — each issue cuts through all relevant layers. Flag layer-only issues that don't deliver demoable value.

### 2) Track coverage

For the full set of issues, check if relevant tracks are represented:

- Feature touching data? → needs `data` track issues.
- Feature with authorization/validation? → needs `rules` track issues.
- Feature with UI? → needs `experience` track issues.
- Feature with external dependencies or failure modes? → needs `resilience` track issues.
- Missing tracks are the highest-signal finding. Flag them.

### 3) Edge cases and failure paths

- **Every user-facing action** should have success AND failure steps or acceptance criteria.
- **Permission boundaries** — what happens when unauthorized user hits this?
- **Empty/loading/error states** in experience issues.
- **Race conditions** — concurrent mutations on same entity?
- **Cascade effects** — what breaks downstream when this entity is deleted?

### 4) Dependency ordering

- **No circular dependencies** — `blocked_by` graph must be a DAG.
- **No forward references** — an issue should not depend on a higher-numbered issue unless there's a clear reason.
- **Data before logic before UI** — schema and services should precede the UI that consumes them.
- **Critical path first** — highest-risk or most-uncertain work should have fewer blockers.

### 5) Step quality

- Every step follows `Target — required behavior` pattern.
- Steps include location context (route, file path, service name, component).
- No vague language: "handle errors appropriately", "set up properly", "add necessary validation".
- `headed: true` steps specify what to verify visually.
- Steps are ordered by implementation sequence.

### 6) PRD completeness

- `decisions` — are there choices made during planning that aren't recorded?
- `open_questions` — do any remain that could block implementation?
- `risks` — are there unacknowledged risks visible from the codebase?
- `use_cases` — does every issue reference at least one use case?
- `in_scope` / `out_of_scope` — do any issues drift outside stated scope?

### 7) Architectural concerns

- **Vendor lock-in** — direct dependency on third-party API without adapter layer?
- **Missing migrations** — schema changes without a data-track issue?
- **Security gaps** — input validation, auth checks, secret handling, rate limiting?
- **Performance at scale** — queries that scan full tables, N+1 patterns, missing pagination?

## AskUserQuestion guidelines

Only ask about things you **cannot resolve from the codebase or plan itself**.

Good questions:
- "Phase 2 adds SSO but no rate limiting on login attempts. Should I add a resilience issue for brute-force protection, or is this handled by an existing middleware?"
- "The plan creates JIT user accounts on SSO callback but doesn't address what happens if the user's email changes in the IdP. Should we track IdP subject ID separately?"
- "Issue 5 has domain verification but no issue for re-verification. Should domains expire or is one-time verification sufficient?"
- "Track coverage: there are no `resilience` issues. The auth flow depends on an external IdP — should we add error handling for IdP downtime?"

Bad questions (never ask these):
- "Do you want me to review the plan?" (you're already doing it)
- "Should issues have tests?" (follow the spec)
- "Is the `blocked_by` correct?" (just fix it)
- "Do you want me to add `tdd: true`?" (just add it)

## Output format

After all fixes and questions are resolved:

```
## Review summary

### Auto-fixed (N issues)
- [list of mechanical fixes applied, grouped by issue ID]

### Findings (N issues)
- [actionable findings with specific issue ID references]

### Track coverage
- intent:     N issues
- experience: N issues
- data:       N issues
- rules:      N issues
- resilience: N issues
- [flag missing tracks]

### Questions resolved
- [questions asked and decisions made]

### PRD updates
- [changes to decisions, open_questions, or risks in prd.yaml]
```

## Anti-patterns

- Reviewing formatting over substance
- Suggesting changes the issue schema doesn't support
- Adding issues for hypothetical future requirements
- Rewriting the entire plan instead of targeted fixes
- Asking about things that are obvious from the codebase
- Proposing architectural changes that contradict recorded decisions in the PRD
