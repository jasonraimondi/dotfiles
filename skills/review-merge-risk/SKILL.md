---
name: review-merge-risk
description: "Analyze the merge risk of a pull request or local branch and emit a verdict (SHIP / SHIP WITH MITIGATIONS / HOLD / DO NOT MERGE) with explicit reversibility analysis. Analysis-only — never approves, comments, or merges. Use when the user says: merge risk, risk to merge, merge safety, risk score, is this PR safe to merge, should I merge this, one-way door, or invokes /review-merge-risk"
---

# PR Merge Risk

Analyze a pull request and produce a conservative merge verdict with explicit reversibility analysis. Reversibility is load-bearing: a 5,000-line PR that's pure additions to a new service can be safer than a 20-line PR that drops a column. **One-way doors** — irreversible actions — are the single biggest risk multiplier.

## Input — PR or local branch

Accept either:

- **PR** — full GitHub PR URL, `owner/repo#123`, `#123` (current repo), or bare PR number. If ambiguous, run `gh pr list` and ask which one.
- **Local branch** — "this branch" / "my changes" with no PR yet. Diff against the merge-base with the default branch: `git diff $(git merge-base HEAD <base>)...HEAD`. No PR exists, so CI checks, review decision, and mergeable status are unavailable — report each as "no PR yet — not available" and run the full risk, reversibility, and blast-radius analysis normally. Detect local merge conflicts with `git merge-tree <base> HEAD`.

## Workflow

1. **Read intent**: PR title, body, and linked issues. Empty/unclear description is itself a risk signal — note it and proceed.
2. **Triage from file paths first** (before reading code): categorize each changed file — migration, auth/session/crypto, public API, infra/IaC, config, internal logic, test, doc. Use the categorization to decide where to read hardest.
3. **Gather** — PR mode (run in parallel; for cross-repo PRs add `--repo owner/repo`):
   - `gh pr view <n> --json title,body,baseRefName,headRefName,author,isDraft,mergeable,mergeStateStatus,reviewDecision,reviews,files,additions,deletions,labels,createdAt,updatedAt`
   - `gh pr diff <n>`
   - `gh pr checks <n>`
   - `gh pr view <n> --comments`

   Local-branch mode: use `git diff $(git merge-base HEAD <base>)...HEAD` and `git log <base>..HEAD` instead; CI, reviews, and mergeable status are "no PR yet — not available".
4. **Read high-risk files in full.** A diff alone hides blast radius; surrounding code reveals it.
5. **Identify one-way doors.** For each meaningful change ask: *if this is wrong and we revert in 15 minutes, are we back to a safe state?* Classify reversibility using the tiers below. Any one-way door pulls the verdict toward HOLD or DO NOT MERGE unless a specific mitigation is in place.
6. **Ask what the diff doesn't show.** Surface unverifiable assumptions: upstream invariants, prod traffic patterns the new path will see, env vars whose defaults differ between code and prod, behavior straddling the deploy boundary, dependencies on flags that flip later. Each unverifiable assumption is a finding.
7. **Score and choose verdict.** Start at 10, apply the rubric (cap each category at its listed range, floor at 1), then pick the verdict tier. If any HIGH factor exists, verdict is at most SHIP WITH MITIGATIONS — and the mitigation must address that factor specifically.
8. **Emit** the report in the exact output format below.

## Reversibility tiers

- **Clean revert** — revert the PR and you're back to safe. Most code-only changes.
- **Revert + data fix** — revert plus a small, well-understood one-time correction (e.g., backfill a column, replay a queue).
- **Revert needs a migration** — undoing requires a forward fix; not instant, but recoverable.
- **One-way door** — irreversible. Examples: destructive DDL (`DROP`, data deletion), public API/field removal once consumers adapt, key rotations once distributed, sent emails/notifications, processed payments, external side-effecting API calls, removed feature flags whose code paths are gone, anything that has already touched a system Claude or the user can't recall.

## Risk Signals (subtract from 10)

Severity in parens is the typical deduction; adjust based on blast radius.

- **One-way doors** (−3 to −5): irreversible operations as defined above. The single biggest risk multiplier — apply this *before* the more specific categories below to avoid double-counting.
- **Backwards compatibility** (−2 to −4): removed/renamed public APIs, changed signatures, removed exports, removed config keys, renamed env vars, response-shape changes, removed fields/columns
- **Destructive migrations** (−2 to −4): `DROP`, `ALTER COLUMN`, adding `NOT NULL` to existing tables, renames, large backfills
- **Config / feature flags** (−1 to −3): default flips, removed flags, flag-gated paths reaching prod without rollout plan
- **Dependencies** (−1 to −3): major version bumps, new deps without prior usage, lockfile-only changes that imply transitive shifts
- **Security-sensitive areas** (−2 to −4): auth, authz, session, crypto, secrets, input parsing, deserialization, SSRF surfaces
- **Test coverage** (−1 to −3): new code with no tests, removed/skipped tests, integration-only paths with mocked DB
- **Size & scope** (−1 to −2): >500 LOC, multiple unrelated changes, touches many packages in a monorepo
- **CI** (−1 to −4): failing required checks, missing checks, flaky required check freshly skipped
- **Mergeability** (−1 to −2): `mergeStateStatus` not `CLEAN` — flag `DIRTY` (conflicts), `BEHIND` (stale base), `BLOCKED` (missing reviews/checks), `UNSTABLE` (non-required check failing)
- **Meta** (−1 to −2): draft, author's first PR to this area, end-of-week or near-release timing
- **Blast radius (monorepo)** (−1 to −3): touches shared libs, public packages, infra, deployment configs

A PR may legitimately score 10 (small, tested, reviewed, green CI, fully reversible, no breaking surface).

## Verdict tiers

Verdict is primary; score is a secondary signal.

- **SHIP** (typically 8–10) — clean revert, no HIGH factors, CI green, reviews satisfied.
- **SHIP WITH MITIGATIONS** (typically 5–7) — proceed *with* a specific mitigation: feature flag, staged rollout, dashboard watch, or named follow-up. Mitigations must address the named risks, not be generic ("monitor closely" is not a mitigation).
- **HOLD** (typically 3–4) — needs concrete fixes before merge; not a one-way door, but unsafe as written.
- **DO NOT MERGE** (typically 1–2) — contains an unmitigated one-way door, breaks downstream consumers without coordination, or fails fundamentally (missing critical tests, broken CI on a load-bearing path).

## Output Format

```
## <PR title> (#<n>) — <repo>

**Verdict: <SHIP | SHIP WITH MITIGATIONS | HOLD | DO NOT MERGE>** (score: N/10)
<one-line summary>

### Reversibility
<tier>: clean revert | revert + data fix | revert needs migration | one-way door
<One or two sentences. If one-way door: name exactly what cannot be undone and why.>

### Blast radius
<One sentence: who/what is affected, at what scale, if this is wrong. Lines-changed is not the metric — "every row in `users`" or "all webhook consumers" is.>

### Key risk factors
- [HIGH|MED|LOW] <factor> — <file:line or evidence>
- ...

### What the diff doesn't show
<Assumptions and questions the reviewer must verify outside the diff. Each item is a specific assumption that, if false, breaks the PR. "None — change is self-contained" is valid with brief justification.>
- <assumption or question>
- ...

### Backwards compatibility
<Explicit: does this break existing callers, consumers, or clients? Name what breaks and who's affected. "None observed" is valid with brief justification.>

### CI & review state
- Checks: <pass/fail summary>
- Reviews: <approvals, requested changes, unresolved threads>
- Mergeable: <mergeStateStatus, conflicts>

### Mitigations to merge with        ← only if verdict is SHIP WITH MITIGATIONS
- <flag / rollout / watch / follow-up — specific, addresses a named risk>
- ...

### Blockers                         ← only if verdict is HOLD or DO NOT MERGE
1. <Specific action with file/area> — addresses <which factor>
2. ...

### Ship it                          ← only if verdict is SHIP
<One line. Note any minor follow-ups as non-blockers.>
```

## Rules

- Cite `file:line` for every code-level risk claim. Vague claims aren't useful.
- In local-branch mode, title the report `<head-branch> → <base-branch> (local, no PR)` and report the **CI & review state** section as "no PR yet — not available".
- **Reversibility**, **Blast radius**, and **What the diff doesn't show** are required output sections — never omit. For trivially safe PRs, write "clean revert", a one-line scope statement, and "none — self-contained" respectively.
- For monorepos, list affected packages/services and weight by blast radius.
- Don't suggest generic advice ("add tests"). Say what to test, where.
- **Never run** `gh pr review`, `gh pr comment`, `gh pr merge`, or `gh pr approve`.
