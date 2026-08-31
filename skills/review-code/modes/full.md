# Mode: `full`

Eight reviewers fan out in parallel; a ninth verifies every finding against the source. The verifier is what separates this mode from `quick`: findings that don't survive a second look at the file never reach the report.

**Run this only when it was asked for** — the user named `full` or `multi`, or the scope is a pull request under final review. Anything else gets `quick`; say that you ran `quick` and why. Nine agents is a real cost.

## Finding schema

Agents 1–7 return a JSON object with a `findings` array. `{"findings": []}` means the reviewer ran and found nothing; a missing or malformed response means the reviewer failed.

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

Resolve scope once (see `../SKILL.md` → *Shared: Resolve scope*), then dispatch all eight reviewers (see `../SKILL.md` → *Shared: Fan-out*).

| # | Reviewer | Brief | Focused scope |
|---|---|---|---|
| 1 | correctness | `lenses/correctness.md` | logic bugs, races, error handling, data loss, broken contracts |
| 2 | tests | `lenses/tests.md` | would each test fail if the bug were present; assertions specific; new branches and error paths covered |
| 3 | security | `lenses/security.md` | OWASP-style; emit all findings with `confidence` set, and skip the pre-filter — the verifier filters |
| 4 | architecture | `lenses/architecture.md` | module depth, coupling, abstraction boundaries, layering, testability at the seams, dead code, speculative structure |
| 5 | standards | `lenses/standards.md` | documented repo standards, then the smell baseline |
| 6 | modularity | `lenses/modularity.md` | `mdlr` opportunities landing on changed files, with buckets |
| 7 | intent | `lenses/intent.md` | descoped items, vacuous tests, skipped verification, interface drift, scope creep |
| 8 | merge risk | `lenses/merge-risk.md` | verdict, reversibility, blast radius, key risk factors, BC, CI/review state |

Every reviewer prompt carries its focused scope from the table, which it stays inside, and its output contract — JSON per the schema for 1–7, native report verbatim for 8.

Category guidance for the two lenses whose findings straddle categories: agent 2 files `correctness` for a test that would not catch the bug and `maintainability` for missing coverage; agent 7 files `correctness` for a missing feature or broken contract, `maintainability` for a vacuous test or skipped verification, `design` for interface drift.

Agent 8's SHIP/HOLD verdict is qualitative and passes through unchanged — the verifier does not re-score it. Its factual claims ("breaks BC", "blast radius: auth path", CI/review state) are checkable, and step 2 checks them.

## Step 2 — Verifier (sequential, after fan-out completes)

Dispatch a ninth Agent. Give it the resolved scope verbatim (it needs this to open files at the correct ref), the seven reviewer finding lists, and Agent 8's report.

For each finding:

1. Open the cited file at the resolved scope and confirm the code matches the claim. For intent findings, confirm **both halves** — the contract really says what the agent claims, and the diff really does or doesn't deliver it. A gap counts only when both sides verify; an imagined requirement gets dropped.
2. Drop findings that don't verify. Weight `confidence`: a `low`-confidence finding survives only with clear, quoted code evidence. Security and intent findings below `high` survive only when verification independently confirms them — filtering happens here rather than at the reviewer, because verification is what promotes a real medium-confidence finding and kills a hallucinated high-confidence one.
3. Group findings at the same root cause and preserve each distinct framing — a line flagged for both a race and a coupling problem keeps both. Link them; leave both standing.
4. Where the fix is small and unambiguous, draft the diff — the files are already open.

Then **fact-check Agent 8**: confirm each factual claim against the diff, flag any that doesn't hold, and leave the SHIP/HOLD verdict itself alone.

Then categorize each surviving finding:

- **critical** — blocks merge: correctness, security, data loss, broken contract, a test that would not catch a regression on a risky path
- **suggestion** — worth raising, doesn't block
- **nit** — style or preference

Then rate the engineering quality of the change:

- **overengineered** — speculative abstractions, unused flexibility, premature generalization, error handling for impossible cases, more code than the problem needs
- **underengineered** — missing validation at real boundaries, no tests for risky paths, ignored edge cases, shortcuts that will break
- **perfectly engineered** — scope matches the problem; no speculative scaffolding and no missing safeguards

Justify in one or two sentences citing specific **verified findings**.

## Final output

1. **Summary** — what the change does, grounded in the diff. Lead with any intent-vs-implementation gap agent 7 surfaced.
2. **Merge risk** — agent 8's verdict and reversibility, then its key risk factors, passed through verbatim where useful. Note any claim the verifier could not confirm.
3. **Engineering quality** — the rating plus its justification.
4. **Findings** grouped by severity, each with `file:line`, the claim, and the verifier's drafted diff where one exists.

## Rules

Shared rules in `../SKILL.md` apply.
