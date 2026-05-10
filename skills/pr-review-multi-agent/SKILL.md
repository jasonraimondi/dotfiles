---
name: pr-review-multi-agent
description: "Orchestrate a five-agent PR review: four reviewers in parallel (correctness/security, design/maintainability, a cross-cutting caveman, and merge risk) plus a verifier that confirms findings against the source. Use when user asks for a 'deep review', 'thorough review', 'multi-agent review', 'audit this PR', or invokes /pr-review-multi-agent"
---

# Multi-Agent PR Review

Five agents: four reviewers fanned out in parallel, one verifier afterwards. Reduces single-pass blind spots and surfaces only verified findings.

Two focused "full" reviewers cover correctness/security and design/maintainability with depth. A third **cross-cutting caveman** reads the whole PR terse and unscoped — different style, no tunnel vision, catches what the focused passes miss. The fourth scores merge risk.

## Input

PR number or URL from the user. If none, run `gh pr list` and ask.

## Finding schema (Agents 1–3 emit JSON)

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

Send a **single message** with four Agent tool calls. Parallel execution requires one message; separate messages run sequentially.

| # | Agent | Style skill | Scope |
|---|-------|-------------|-------|
| 1 | correctness + security (full) | pr-review-full | logic bugs, races, error handling, auth, injection, data loss, broken contracts |
| 2 | design + maintainability (full) | pr-review-full | naming, abstraction, test gaps, missing docs, dead code, unclear control flow |
| 3 | cross-cutting caveman | pr-review-caveman | unscoped: anything across correctness, security, design, maintainability — terse, surface what looks worst |
| 4 | merge risk | pr-merge-risk | verdict (SHIP / SHIP WITH MITIGATIONS / HOLD / DO NOT MERGE), reversibility, blast radius, key risk factors, BC, CI/review state |

Every reviewer prompt must include all four:

1. **PR identifier** (URL, `owner/repo#n`, or bare number).
2. **Focused scope** (the row's Scope cell — don't widen).
3. **Style skill to invoke** via the Skill tool before reviewing (the row's Style-skill cell).
4. **Output requirement** — Agents 1–3: emit findings as JSON matching the schema above. Agent 4: return its native report verbatim.

Agent 4's report passes through to the final output unchanged and is **not** subject to verification in Step 2 — merge-risk analysis is qualitative and self-contained.

## Step 2 — Verifier (sequential, after fan-out completes)

Dispatch a fifth Agent with the **three reviewer finding lists** (Agents 1–3 only). For each finding it must:

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

1. **Summary** — what the PR does, grounded in the diff (not the description).
2. **Merge risk** — verdict and reversibility from Agent 4, followed by its key risk factors. Pass through Agent 4's report verbatim where useful.
3. **Engineering quality** — rating (overengineered / underengineered / perfectly engineered) + 1–2 sentence justification.
4. **Findings** grouped by severity, each with `file:line`, claim, and a suggested diff where applicable.

## Rules

- Never approve, comment on, or merge the PR.
- Don't run the verifier in parallel with reviewers — it depends on their output.
- If a reviewer fails or returns nothing, note it in the summary; don't silently drop.
