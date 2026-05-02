---
name: pr-review-multi-agent
description: Run a rigorous multi-agent review on a pull request. Use when the user asks to review, audit, or critique a PR and wants high-signal findings rather than a single-pass summary. Dispatches five specialized subagents (correctness/security and design/maintainability in full and caveman modes, plus merge-risk scoring), then a verifier that confirms claims against the code, deduplicates, and categorizes findings as critical, suggestion, or nit.
---

# Multi-Agent PR Review

Review PR `$ARGUMENTS` by dispatching six agents: five reviewers in parallel, then one verifier.

## Finding Schema

Every reviewer outputs JSON findings with this shape:

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

## Agents

### Agent 1 — correctness + security (full)

Run `Skill(pr-review-full)` scoped to logic bugs, race conditions, error handling, auth, injection, data loss, and broken API contracts.

### Agent 2 — correctness + security (caveman)

Run `Skill(pr-review-caveman)` scoped to the same: logic bugs, race conditions, error handling, auth, injection, data loss, and broken API contracts.

### Agent 3 — design + maintainability (full)

Run `Skill(pr-review-full)` scoped to naming, abstraction, test coverage gaps, missing docs, dead code, and unclear control flow.

### Agent 4 — design + maintainability (caveman)

Run `Skill(pr-review-caveman)` scoped to the same: naming, abstraction, test coverage gaps, missing docs, dead code, and unclear control flow.

### Agent 5 — merge risk

Run `Skill(pr-merge-risk)` to produce a 1-10 merge-risk score with key risk factors, backwards-compat notes, and CI/review state. Output the full report verbatim — it does not use the finding schema above.

### Agent 6 — verifier

Take the four reviewer finding lists (Agents 1-4). For each finding:

1. Open the cited file and confirm the code matches the claim.
2. Drop findings that don't verify.
3. Merge findings that point at the same root cause.

Then categorize against this bar:

- **critical** — blocks merge: correctness, security, data loss, broken contract, missing test for a risky path
- **suggestion** — worth raising, doesn't block
- **nit** — style or preference

**Caps:** 5 critical, 10 suggestions, nits collapsed into a single list.

## Final Output

1. **Summary** — what the PR does, grounded in the diff (not the description).
2. **Merge risk** — score and key factors from Agent 5.
3. **Findings** grouped by severity, each with `file:line`, claim, and a suggested diff where applicable.
