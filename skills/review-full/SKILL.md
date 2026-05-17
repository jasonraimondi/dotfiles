---
name: review-full
description: Single-pass review of a pull request or local changes for correctness, security, and quality. Reads the diff plus the changed files in full, emits findings grouped by severity with a verdict
---

# Code Review

Single-pass review. One model, one read, one report.

## Input — resolve the scope first

Review a pull request or local changes:

1. **PR** — PR number or URL: `gh pr view <n> --json title,body,baseRefName,headRefName,files` and `gh pr diff <n>`.
2. **Branch** — "this branch" / "my changes" with no PR: diff against the merge-base with the default branch — `git diff $(git merge-base HEAD <base>)...HEAD`.
3. **Working tree** — named files or "these changes": `git diff` (unstaged) and `git diff --staged`, or read the named files directly.
4. **Unclear** — no PR given and a clean working tree: run `gh pr list` and ask which PR. Otherwise ask which scope is meant.

## Workflow

1. **Resolve scope** and get the diff (see Input).
2. **Read changed files in full** — never review a diff in isolation; surrounding code determines correctness.
3. **Analyze** each change against the checklist below; skip dimensions that don't apply.
4. **Emit** findings grouped by severity, then a verdict.

## Checklist

- **Correctness** — logic errors, edge cases, off-by-ones, null/undefined paths
- **Security** — injection, auth gaps, secret exposure, unsafe deserialization
- **Breaking changes** — API contract changes, removed exports, schema migrations
- **Tests** — new behavior has tests; existing tests aren't weakened
- **Naming & clarity** — variables, functions, types express intent
- **Performance** — unnecessary allocations, N+1 queries, missing indexes

## Output

```
## <PR title (#n), or branch/scope description>

### Critical
1. file:line — finding

### Suggestions
2. file:line — finding

### Nitpicks
3. file:line — finding

### Verdict
APPROVE | REQUEST_CHANGES | COMMENT — one-sentence rationale
```

Omit empty sections. Be direct — no filler praise.

## Rules

- Never approve or submit a review on behalf of the user without explicit confirmation.
- Flag uncertainty — say so rather than guessing.
- Stay scoped to the diff. Don't review unchanged code unless directly affected.
