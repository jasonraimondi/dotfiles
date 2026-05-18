---
name: review-multi-agent
description: "Orchestrate a seven-agent PR review: six reviewers in parallel (correctness, dedicated security, architecture/design, a cross-cutting caveman, a tests reviewer, and merge risk) plus a verifier that confirms findings against the source. Use when user asks for a 'deep review', 'thorough review', 'multi-agent review', 'audit this PR', or invokes /review-multi-agent"
---

# Multi-Agent PR Review

Seven agents: six reviewers fanned out in parallel, one verifier afterwards. Reduces single-pass blind spots and surfaces only verified findings.

A **correctness** reviewer and an **architecture/design** reviewer split logic from structure. A dedicated **security** reviewer runs OWASP-style analysis. A **cross-cutting caveman** reads the whole change terse and unscoped — different style, no tunnel vision, catches what the focused passes miss. A **tests reviewer** checks whether the tests actually exercise the risky paths and would fail if the bug were present. The sixth scores merge risk.

## Input — resolve the scope once

Review a pull request or local changes. Resolve the scope here, then pass the *same resolved scope* to every reviewer **and to the verifier** so they all review the same code:

1. **PR** — PR number or URL.
2. **Branch** — "this branch" / "my changes": the merge-base diff against the default branch. Detect the default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, or `git symbolic-ref refs/remotes/origin/HEAD`) — don't assume `main`. If the merge-base diff is very large (a long-running branch), note it in the final summary: per-reviewer coverage degrades on huge diffs.
3. **Working tree** — named files or "these changes": the staged/unstaged diff.
4. **Unclear** — no PR and a clean working tree: run `gh pr list` and ask. Otherwise ask which scope.

## Finding schema (Agents 1–5 emit JSON)

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
| 2 | security (dedicated) | review-security | OWASP-style: injection, XSS, auth/authz, SSRF, deserialization, crypto, secrets — emit all findings with `confidence` set; do **not** pre-filter |
| 3 | architecture + design | review-architecture | module depth, coupling, abstraction boundaries, layering, testability at the seams, naming/clarity, dead code, speculative structure, noisy/redundant/stale comments and refactors that would obviate a comment |
| 4 | cross-cutting caveman | review-caveman | unscoped: anything across correctness, security, design, maintainability — terse, surface what looks worst |
| 5 | tests reviewer | testing-tdd | do the tests exercise the risky and changed paths; would each test still pass if the bug were present; are assertions correct and specific; missing cases for new branches and error paths — scoped to the change |
| 6 | merge risk | review-merge-risk | verdict (SHIP / SHIP WITH MITIGATIONS / HOLD / DO NOT MERGE), reversibility, blast radius, key risk factors, BC, CI/review state |

Every reviewer prompt must include all four:

1. **Review scope** — the resolved scope from Input (PR identifier, or the branch / working-tree diff instruction), passed verbatim so every reviewer reviews the same code.
2. **Focused scope** (the row's Scope cell — don't widen). Adapt findings to the idioms of the change's language.
3. **Style skill to invoke** via the Skill tool before reviewing (the row's Style-skill cell).
4. **Output requirement** — Agents 1–5: emit findings as JSON matching the schema above (Agent 5: `category: "correctness"` for a test that would not catch the bug, `category: "maintainability"` for missing coverage). Agent 6: return its native report verbatim.

Agent 6's SHIP/HOLD verdict is qualitative and passes through unchanged — it is not re-scored. But its factual claims ("breaks BC", "blast radius: auth path", CI/review state) are checkable; the verifier fact-checks them in Step 2.

## Step 2 — Verifier (sequential, after fan-out completes)

Dispatch a seventh Agent. Give it the **resolved scope** (verbatim, as passed to the reviewers — it needs this to open files at the correct ref), the **five reviewer finding lists** (Agents 1–5), and **Agent 6's report**.

For each finding:

1. Open the cited file at the resolved scope and confirm the code matches the claim.
2. Drop findings that don't verify. Weight `confidence`: a `low`-confidence finding survives only with clear, quoted code evidence. Security findings below `high` confidence survive only if verification independently confirms them — this is where security filtering happens, not at the reviewer, because verification is what promotes a real medium-confidence finding and kills a hallucinated high-confidence one.
3. Group findings at the same root cause; preserve each distinct framing (a line flagged for both a race and a coupling problem keeps both) — link, don't collapse.
4. Where the fix is small and unambiguous, draft the diff — the files are already open.

Then **fact-check Agent 6**: for each factual claim in its report (BC, blast radius, CI/review state), confirm it against the diff. Flag any claim that doesn't hold; leave the SHIP/HOLD verdict itself unchanged.

Then **check intent vs. implementation**: if the resolved scope is a PR, fetch its description and compare it against the verified diff — if the change does materially less or more than it claims, add that as a finding. For branch/working-tree scope there is no description; skip this.

Then categorize each surviving finding against this bar:

- **critical** — blocks merge: correctness, security, data loss, broken contract, test that would not catch a regression on a risky path
- **suggestion** — worth raising, doesn't block
- **nit** — style or preference

Then rate the engineering quality of the change as one of:

- **overengineered** — speculative abstractions, unused flexibility, premature generalization, error handling for impossible cases, more code than the problem needs
- **underengineered** — missing validation at real boundaries, no tests for risky paths, ignored edge cases, shortcuts that will break
- **perfectly engineered** — scope matches the problem; no speculative scaffolding and no missing safeguards

Justify in 1–2 sentences citing specific **verified findings** (not unverified claims or the raw diff).

## Final output

1. **Summary** — what the change does, grounded in the diff. If intent vs. implementation flagged a mismatch, state it here.
2. **Merge risk** — verdict and reversibility from Agent 6, followed by its key risk factors. Pass through Agent 6's report verbatim where useful; note any claim the verifier flagged as unconfirmed.
3. **Engineering quality** — rating (overengineered / underengineered / perfectly engineered) + 1–2 sentence justification.
4. **Findings** grouped by severity, each with `file:line`, claim, and the verifier's drafted diff where one exists.

## Rules

- Never approve, comment on, or merge the PR.
- If a reviewer fails or returns nothing, note it in the summary; don't silently drop.
