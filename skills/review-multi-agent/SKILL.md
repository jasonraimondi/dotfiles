---
name: review-multi-agent
description: "Orchestrate a seven-agent PR review: six reviewers in parallel (correctness, dedicated security, architecture/design, a cross-cutting caveman, a comments auditor, and merge risk) plus a verifier that confirms findings against the source. Use when user asks for a 'deep review', 'thorough review', 'multi-agent review', 'audit this PR', or invokes /review-multi-agent"
---

# Multi-Agent PR Review

Seven agents: six reviewers fanned out in parallel, one verifier afterwards. Reduces single-pass blind spots and surfaces only verified findings.

A **correctness** reviewer and an **architecture/design** reviewer split logic from structure. A dedicated **security** reviewer runs OWASP-style analysis with high-confidence-only filtering. A **cross-cutting caveman** reads the whole change terse and unscoped — different style, no tunnel vision, catches what the focused passes miss. A **comments auditor** flags noisy, redundant, or stale comments and refactors that would obviate them. The sixth scores merge risk.

## Input — resolve the scope once

Review a pull request or local changes. Resolve the scope here, then pass the *same resolved scope* to every reviewer so they all review the same code:

1. **PR** — PR number or URL.
2. **Branch** — "this branch" / "my changes": the merge-base diff against the default branch.
3. **Working tree** — named files or "these changes": the staged/unstaged diff.
4. **Unclear** — no PR and a clean working tree: run `gh pr list` and ask. Otherwise ask which scope.

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

Send a **single message** with six Agent tool calls. Parallel execution requires one message; separate messages run sequentially.

| # | Agent | Style skill | Scope |
|---|-------|-------------|-------|
| 1 | correctness (full) | review-full | logic bugs, races, error handling, data loss, broken contracts |
| 2 | security (dedicated) | review-security | OWASP-style: injection, XSS, auth/authz, SSRF, deserialization, crypto, secrets — HIGH-confidence findings only |
| 3 | architecture + design | review-architecture | module depth, coupling, abstraction boundaries, layering, testability at the seams, naming/clarity, dead code, speculative structure |
| 4 | cross-cutting caveman | review-caveman | unscoped: anything across correctness, security, design, maintainability — terse, surface what looks worst |
| 5 | comments auditor | best-practices-comments | journal/noise/redundant/mumbling/nonlocal comments, stale or misleading comments, refactors that would obviate a comment — scoped to lines the PR adds or modifies |
| 6 | merge risk | review-merge-risk | verdict (SHIP / SHIP WITH MITIGATIONS / HOLD / DO NOT MERGE), reversibility, blast radius, key risk factors, BC, CI/review state |

Every reviewer prompt must include all four:

1. **Review scope** — the resolved scope from Input (PR identifier, or the branch / working-tree diff instruction), passed verbatim so every reviewer reviews the same code.
2. **Focused scope** (the row's Scope cell — don't widen).
3. **Style skill to invoke** via the Skill tool before reviewing (the row's Style-skill cell).
4. **Output requirement** — Agents 1–5: emit findings as JSON matching the schema above (Agent 2: only HIGH-confidence security findings; Agent 5: use `category: "maintainability"` and quote the offending comment in `code_evidence`). Agent 6: return its native report verbatim.

Agent 6's report passes through to the final output unchanged and is **not** subject to verification in Step 2 — merge-risk analysis is qualitative and self-contained.

## Step 2 — Verifier (sequential, after fan-out completes)

Dispatch a seventh Agent with the **five reviewer finding lists** (Agents 1–5 only). For each finding it must:

1. Open the cited file and confirm the code matches the claim.
2. Drop findings that don't verify.
3. Merge findings that point at the same root cause.

Then categorize against this bar:

- **critical** — blocks merge: correctness, security, data loss, broken contract, missing test for a risky path
- **suggestion** — worth raising, doesn't block
- **nit** — style or preference

**Caps:** 5 critical, 10 suggestions, nits collapsed into a single list.

Then rate the engineering quality of the change as one of:

- **overengineered** — speculative abstractions, unused flexibility, premature generalization, error handling for impossible cases, more code than the problem needs
- **underengineered** — missing validation at real boundaries, no tests for risky paths, ignored edge cases, shortcuts that will break
- **perfectly engineered** — scope matches the problem; no speculative scaffolding and no missing safeguards

Justify in 1–2 sentences citing specific evidence from the verified findings or the diff.

## Final output

1. **Summary** — what the change does, grounded in the diff (not the description).
2. **Merge risk** — verdict and reversibility from Agent 6, followed by its key risk factors. Pass through Agent 6's report verbatim where useful.
3. **Engineering quality** — rating (overengineered / underengineered / perfectly engineered) + 1–2 sentence justification.
4. **Findings** grouped by severity, each with `file:line`, claim, and a suggested diff where applicable.

## Rules

- Never approve, comment on, or merge the PR.
- Don't run the verifier in parallel with reviewers — it depends on their output.
- If a reviewer fails or returns nothing, note it in the summary; don't silently drop.
