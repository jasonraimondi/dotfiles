# Mode: `full`

Eight reviewers fan out in parallel; a ninth verifies every finding against the source. The verifier is what separates this mode from `quick`: findings that don't survive a second look at the file never reach the report.

**Run this only when it was asked for** — the user named `full` or `multi`, or the scope is a pull request under final review. Anything else gets `quick`; say that you ran `quick` and why. Nine agents is a real cost.

## Step 1 — Dispatch reviewers in parallel

Resolve scope once (see `../SKILL.md` → *Shared: Resolve scope*), then dispatch all eight reviewers (see `../SKILL.md` → *Shared: Fan-out*).

| # | Reviewer | Brief | Focused scope |
|---|---|---|---|
| 1 | correctness | `lenses/correctness.md` | logic bugs, races, error handling, data loss, broken contracts, leftover state |
| 2 | tests | `lenses/tests.md` | would each test fail if the bug were present; assertions specific; new branches and error paths covered |
| 3 | security | `lenses/security.md` | OWASP-style; emit all findings with confidence set, and skip the pre-filter — the verifier filters |
| 4 | architecture | `lenses/architecture.md` | module depth, coupling, abstraction boundaries, layering, testability at the seams, dead code, speculative structure |
| 5 | standards | `lenses/standards.md` | documented repo standards and design records, comments, then the smell baseline |
| 6 | modularity | `lenses/modularity.md` | `mdlr` opportunities landing on changed files, weighed and advisory |
| 7 | intent | `lenses/intent.md` | descoped items, vacuous tests, skipped verification, interface drift, scope creep |
| 8 | merge risk | `lenses/merge-risk.md` | verdict, reversibility, blast radius, key risk factors, BC, CI/review state |

Every reviewer prompt carries its focused scope from the table, which it stays inside, and its output contract:

- **Reviewers 1–7** return findings in the anatomy from `../report.md`, each with a proposed severity and a `Confidence: high | medium | low` line, then the reviewer's `Engineering:` line. `No findings.` means the reviewer ran and found nothing; a response with neither means the reviewer failed.
- **Reviewer 8** returns its native report verbatim.

Agent 8's SHIP/HOLD verdict is qualitative and passes through unchanged — the verifier does not re-score it. Its factual claims ("breaks BC", "blast radius: auth path", CI/review state) are checkable, and step 2 checks them.

## Step 2 — Verifier (sequential, after fan-out completes)

Dispatch a ninth Agent. Give it the resolved scope verbatim (it needs this to open files at the correct ref), the path to `report.md`, the seven reviewer finding lists, and Agent 8's report.

For each finding:

1. Open every cited location at the resolved scope and confirm the code matches the claim, then walk the scenario through the code step by step. For intent findings, confirm **both halves** — the contract really says what the agent claims, and the diff really does or doesn't deliver it. A gap counts only when both sides verify; an imagined requirement gets dropped.
2. Drop findings the code contradicts. Weight confidence: a `low`-confidence finding survives only with clear, cited code evidence. Security and intent findings below `high` survive only when verification independently confirms them — filtering happens here rather than at the reviewer, because verification is what promotes a real medium-confidence finding and kills a hallucinated high-confidence one. A finding the code neither confirms nor contradicts moves to *Could not verify*, with what would settle it.
3. Group findings at the same root cause and preserve each distinct framing — a line flagged for both a race and a coupling problem keeps both. Link them; leave both standing.
4. Where the fix is small and unambiguous, draft the diff — the files are already open.

Then **fact-check Agent 8**: confirm each factual claim against the diff, flag any that doesn't hold, and leave the SHIP/HOLD verdict itself alone.

Then set each surviving finding's severity (see `../report.md` → *Severity*). The reviewer's proposal is a starting point; the verifier has seen the code twice.

Then set the engineering rating (see `../report.md` → *Engineering rating*), resting it on **verified findings**.

## Final output

The report in `../report.md`, with one section added after *Summary*:

```
## Merge risk

**<SHIP | SHIP WITH MITIGATIONS | HOLD | DO NOT MERGE>** (score: N/10)

- Reversibility: <tier, and what cannot be undone>
- Blast radius: <who and what is affected, at what scale>
- Mitigations: <only for SHIP WITH MITIGATIONS>
```

Agent 8's remaining material lands in the shared sections:

- A key risk factor that verified becomes a finding, or joins the finding already covering it.
- *What the diff doesn't show* becomes open questions for the author.
- A claim the verifier could not confirm goes under *Could not verify*.

Findings carry the verifier's drafted diff under *Suggested fix* where one exists.

## Rules

Shared rules in `../SKILL.md` apply.
