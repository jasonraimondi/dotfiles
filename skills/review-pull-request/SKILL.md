---
name: review-pull-request
description: "Review a pull request for correctness, security, and quality. Use when user says: review PR, check this PR, review pull request, or provides a GitHub PR URL or number."
---

# Review Pull Request

## Input Resolution

1. If a PR number or URL is provided, use it directly.
2. If no PR is specified, run `gh pr list` for the current repo and ask which PR to review.

## Workflow

1. **Fetch context**: Run `gh pr view <number> --json title,body,baseRefName,headRefName,files` and `gh pr diff <number>` to get the full changeset.
2. **Read changed files**: Read each modified file to understand surrounding context — never review a diff in isolation.
3. **Analyze** each change against the review checklist below.
4. **Output findings** grouped by severity, then a summary verdict.

## Review Checklist

- **Correctness**: Logic errors, edge cases, off-by-ones, null/undefined paths
- **Security**: Injection, auth gaps, secret exposure, unsafe deserialization
- **Breaking changes**: API contract changes, removed exports, schema migrations
- **Tests**: New behavior has tests; existing tests aren't weakened
- **Naming & clarity**: Variables, functions, and types express intent
- **Performance**: Unnecessary allocations, N+1 queries, missing indexes

Skip dimensions that don't apply to the changeset.

## Output Format

```
## <PR title> (#number)

### Critical
- file:line — finding

### Suggestions
- file:line — finding

### Nitpicks
- file:line — finding

### Verdict
APPROVE | REQUEST_CHANGES | COMMENT — one-sentence rationale
```

Omit empty severity sections. Be direct — no filler praise.

## Rules

- Never approve or submit a review on behalf of the user without explicit confirmation.
- Flag uncertainty — if you lack context to judge a change, say so rather than guessing.
- Stay scoped to the diff. Don't review unchanged code unless it's directly affected.
