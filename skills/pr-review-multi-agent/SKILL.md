---
name: pr-review-multi-agent
description: High-rigor multi-agent PR review. Fans out five specialized reviewers in parallel (correctness/security and design/maintainability in full + caveman modes, plus merge-risk scoring), then a verifier confirms each claim against the diff and dedupes. Use when user asks for a "deep review", "thorough review", "multi-agent review", "audit this PR", "fan out review", or invokes /pr-review-multi-agent — and wants higher signal than a single-pass review.
---

# Multi-Agent PR Review

Six agents: five reviewers fanned out in parallel, one verifier afterwards. Reduces single-pass blind spots and surfaces only verified findings.

## Input

PR number or URL from the user. If none, run `gh pr list` and ask.

## Finding schema (Agents 1–4 emit JSON)

```json
{
  "file": "path/to/file",
  "lines": "L42 or L88-140",
  "severity": "critical | suggestion | nit",
  "category": "correctness | security | design | maintainability",
  "claim": "what's wrong",
  "code_evidence": "quoted snippet from the diff",
  "confidence": "high | medium | low"
}
```

## Step 1 — Dispatch reviewers in parallel

Send a **single message** with five Agent tool calls. Parallel execution requires one message; separate messages run sequentially.

| # | Agent | Style skill | Scope |
|---|-------|-------------|-------|
| 1 | correctness + security (full) | pr-review-full | logic bugs, races, error handling, auth, injection, data loss, broken contracts |
| 2 | correctness + security (caveman) | pr-review-caveman | same scope, terse output |
| 3 | design + maintainability (full) | pr-review-full | naming, abstraction, test gaps, missing docs, dead code, unclear control flow |
| 4 | design + maintainability (caveman) | pr-review-caveman | same scope, terse output |
| 5 | merge risk | pr-merge-risk | 1–10 score, key risk factors, backwards-compat, CI/review state |

Each reviewer prompt must include: the PR identifier, the focused scope, the style skill to invoke, and the finding-schema requirement (Agents 1–4 only). Agent 5 returns its native report verbatim.

## Step 2 — Verifier (sequential, after fan-out completes)

Dispatch a sixth Agent with the four reviewer finding lists. For each finding it must:

1. Open the cited file and confirm the code matches the claim.
2. Drop findings that don't verify.
3. Merge findings that point at the same root cause.

Then categorize against this bar:

- **critical** — blocks merge: correctness, security, data loss, broken contract, missing test for a risky path
- **suggestion** — worth raising, doesn't block
- **nit** — style or preference

**Caps:** 5 critical, 10 suggestions, nits collapsed into a single list.

## Final output

1. **Summary** — what the PR does, grounded in the diff (not the description).
2. **Merge risk** — score and key factors from Agent 5.
3. **Findings** grouped by severity, each with `file:line`, claim, and a suggested diff where applicable.

## Rules

- Never approve, comment on, or merge the PR.
- Don't run the verifier in parallel with reviewers — it depends on their output.
- If a reviewer fails or returns nothing, note it in the summary; don't silently drop.
