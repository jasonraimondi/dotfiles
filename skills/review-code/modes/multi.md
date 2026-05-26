# Mode: `multi`

Six reviewers fan out in parallel; a seventh verifies every finding against the source. Cuts single-pass blind spots and surfaces only verified findings.

Roles split on purpose: **correctness** and **architecture** separate logic from structure, a dedicated **security** pass runs OWASP-style, a **tests** reviewer checks the tests would fail if the bug were present, an **intent** pass audits the diff against its stated intent (descoped items, vacuous tests, interface drift), and **merge risk** scores shippability.

## Finding schema

Each of Agents 1–5 returns a JSON object with a `findings` array. `{"findings": []}` means the reviewer ran and found nothing; a missing or malformed response means the reviewer failed.

```json
{
  "findings": [
    {
      "file": "path/to/file",
      "lines": "L42 or L88-140",
      "code_evidence": "verbatim + or - line from the diff (or surrounding unchanged context only when the bug is missing code)",
      "claim": "what the code does and what it should do instead",
      "impact": "what breaks; who feels it",
      "severity": "critical | suggestion | nit",
      "category": "correctness | security | design | maintainability",
      "confidence": "high | medium | low",
      "suggested_fix": "optional — one line or small diff snippet; omit when no small fix exists"
    }
  ]
}
```

## Step 1 — Dispatch reviewers in parallel

Resolve scope once (see SKILL.md → *Shared: Resolve scope*), then dispatch all six Agent calls in a **single message** — separate messages run sequentially. Pass the resolved scope verbatim to every reviewer **and to the verifier** so they all review the same code.

| # | Agent | Skill to invoke | Focused scope |
|---|---|---|---|
| 1 | correctness | `/review-code standard` | logic bugs, races, error handling, data loss, broken contracts |
| 2 | security | `/review-code security` | OWASP-style; emit all findings with `confidence` set; do **not** pre-filter |
| 3 | architecture | `/review-code architecture` | module depth, coupling, abstraction boundaries, layering, testability at the seams, naming/clarity, dead code, speculative structure |
| 4 | tests | `testing-tdd` (external skill) | do the tests exercise the risky and changed paths; would each test still pass if the bug were present; assertions specific; missing cases for new branches and error paths |
| 5 | intent | `/review-code intent` | audit the diff against its stated intent: descoped items, vacuous tests, skipped verification, interface drift, scope creep |
| 6 | merge risk | `/review-code merge-risk` | verdict (SHIP / SHIP WITH MITIGATIONS / HOLD / DO NOT MERGE), reversibility, blast radius, key risk factors, BC, CI/review state |

Every reviewer prompt includes:

1. **Review scope** — resolved scope, passed verbatim so every reviewer reviews the same code.
2. **Focused scope** — the row's "focused scope" cell; don't widen. Adapt findings to the change's language.
3. **Skill to invoke** — via the Skill tool before reviewing (this skill in a specific mode, or the named external skill).
4. **Output** — Agents 1–5: JSON per the schema above (Agent 4: `category: "correctness"` for a test that would not catch the bug, `category: "maintainability"` for missing coverage; Agent 5: pick the category that fits the gap — `correctness` for missing feature/broken contract, `maintainability` for vacuous tests or skipped verification, `design` for interface drift). Agent 6: return its native report verbatim.

Agent 6's SHIP/HOLD verdict is qualitative and passes through unchanged — not re-scored. Its factual claims ("breaks BC", "blast radius: auth path", CI/review state) are checkable; the verifier fact-checks them in Step 2.

## Step 2 — Verifier (sequential, after fan-out completes)

Dispatch a seventh Agent. Give it the resolved scope (verbatim, as passed to the reviewers — it needs this to open files at the correct ref), the five reviewer finding lists (Agents 1–5), and Agent 6's report.

For each finding:

1. Open the cited file at the resolved scope and confirm the code matches the claim. For intent findings (Agent 5), confirm both halves — the stated intent (PR description, commit message, plan doc) really says what the agent claims it says, and the diff really does/doesn't deliver what the agent claims. A gap counts only if both sides verify; an imagined requirement gets dropped.
2. Drop findings that don't verify. Weight `confidence`: a `low`-confidence finding survives only with clear, quoted code evidence. Security and intent findings below `high` confidence survive only if verification independently confirms them — filtering happens here, not at the reviewer, since verification is what promotes a real medium-confidence finding and kills a hallucinated high-confidence one.
3. Group findings at the same root cause; preserve each distinct framing (a line flagged for both a race and a coupling problem keeps both) — link, don't collapse.
4. Where the fix is small and unambiguous, draft the diff — the files are already open.

Then **fact-check Agent 6**: for each factual claim in its report (BC, blast radius, CI/review state), confirm it against the diff. Flag any claim that doesn't hold; leave the SHIP/HOLD verdict itself unchanged.

Then categorize each surviving finding against this bar:

- **critical** — blocks merge: correctness, security, data loss, broken contract, test that would not catch a regression on a risky path
- **suggestion** — worth raising, doesn't block
- **nit** — style or preference

Then rate the engineering quality of the change:

- **overengineered** — speculative abstractions, unused flexibility, premature generalization, error handling for impossible cases, more code than the problem needs
- **underengineered** — missing validation at real boundaries, no tests for risky paths, ignored edge cases, shortcuts that will break
- **perfectly engineered** — scope matches the problem; no speculative scaffolding and no missing safeguards

Justify in 1–2 sentences citing specific **verified findings** (not unverified claims or the raw diff).

## Final output

1. **Summary** — what the change does, grounded in the diff. If Agent 5 surfaced an intent-vs-implementation gap (descoped item, vacuous test, interface drift), state it here.
2. **Merge risk** — verdict and reversibility from Agent 6, followed by its key risk factors. Pass through Agent 6's report verbatim where useful; note any claim the verifier flagged as unconfirmed.
3. **Engineering quality** — rating (overengineered / underengineered / perfectly engineered) + 1–2 sentence justification.
4. **Findings** grouped by severity, each with `file:line`, claim, and the verifier's drafted diff where one exists.

## Rules (mode-specific)

- If a reviewer fails or returns nothing, note it in the summary; don't silently drop.
- The verifier fact-checks Agent 6's claims but does not re-derive the SHIP/HOLD verdict.

Shared rules in SKILL.md apply.
