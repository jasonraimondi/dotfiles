# Mode: `merge-risk`

Conservative merge verdict with explicit reversibility analysis. **Reversibility is load-bearing** — a 5,000-line PR of pure additions to a new service can be safer than a 20-line PR that drops a column. **One-way doors** (irreversible actions) are the single biggest risk multiplier.

## Workflow

1. **Read intent** — PR title, body, linked issues. Empty/unclear description is itself a risk signal.
2. **Triage from file paths** before reading code: migration, auth/session/crypto, public API, infra/IaC, config, internal logic, test, doc. Decide where to read hardest.
3. **Gather** (PR mode, run in parallel; add `--repo owner/repo` for cross-repo):
   - `gh pr view <n> --json title,body,baseRefName,headRefName,author,isDraft,mergeable,mergeStateStatus,reviewDecision,reviews,files,additions,deletions,labels,createdAt,updatedAt`
   - `gh pr diff <n>`
   - `gh pr checks <n>`
   - `gh pr view <n> --comments`

   Local-branch mode: `git diff $(git merge-base HEAD <base>)...HEAD` and `git log <base>..HEAD`; CI/reviews/mergeable are "no PR yet — not available".
4. **Read high-risk files in full.** Diff alone hides blast radius.
5. **Identify one-way doors.** *If this is wrong and we revert in 15 minutes, are we back to safe?* Classify reversibility (tiers below). Any one-way door pulls verdict toward HOLD or DO NOT MERGE unless a specific mitigation addresses it.
6. **Ask what the diff doesn't show.** Upstream invariants, prod traffic patterns, env-var drift, behavior straddling the deploy boundary, dependencies on flags that flip later. Each unverifiable assumption is a finding.
7. **Score and choose verdict.** Start at 10, apply rubric (cap each category, floor at 1). If any HIGH factor exists, verdict is at most SHIP WITH MITIGATIONS — and the mitigation must address that factor.

## Reversibility tiers

- **Clean revert** — revert and you're back to safe. Most code-only changes.
- **Revert + data fix** — revert plus a small, well-understood one-time correction (backfill, replay).
- **Revert needs a migration** — undoing requires a forward fix; recoverable but not instant.
- **One-way door** — irreversible: destructive DDL, public API removal once consumers adapt, key rotations once distributed, sent emails/notifications, processed payments, external side effects, removed feature flags whose code paths are gone.

## Risk signals (subtract from 10)

Severity in parens is typical; adjust for blast radius.

- **One-way doors** (−3 to −5) — apply *before* more specific categories to avoid double-counting
- **Backwards compatibility** (−2 to −4) — removed/renamed APIs, signatures, exports, config keys, env vars, response shapes, fields/columns
- **Destructive migrations** (−2 to −4) — `DROP`, `ALTER COLUMN`, adding `NOT NULL` to existing tables, renames, large backfills
- **Config / feature flags** (−1 to −3) — default flips, removed flags, gated paths reaching prod without rollout plan
- **Dependencies** (−1 to −3) — major bumps, new deps without prior usage, lockfile-only changes implying transitive shifts
- **Security-sensitive areas** (−2 to −4) — auth, authz, session, crypto, secrets, input parsing, deserialization, SSRF surfaces
- **Test coverage** (−1 to −3) — new code with no tests, removed/skipped tests, integration-only paths with mocked DB
- **Size & scope** (−1 to −2) — >500 LOC, multiple unrelated changes, touches many packages in a monorepo
- **CI** (−1 to −4) — failing required checks, missing checks, flaky check newly skipped
- **Mergeability** (−1 to −2) — `mergeStateStatus` not `CLEAN`: `DIRTY`, `BEHIND`, `BLOCKED`, `UNSTABLE`
- **Meta** (−1 to −2) — draft, author's first PR to this area, end-of-week or near-release timing
- **Blast radius (monorepo)** (−1 to −3) — shared libs, public packages, infra, deployment configs

A PR can legitimately score 10 (small, tested, reviewed, green CI, fully reversible, no breaking surface).

## Verdict tiers

Verdict primary; score secondary.

- **SHIP** (typically 8–10) — clean revert, no HIGH factors, CI green, reviews satisfied
- **SHIP WITH MITIGATIONS** (typically 5–7) — proceed *with* a specific mitigation (flag, staged rollout, dashboard watch, named follow-up). Generic "monitor closely" is not a mitigation.
- **HOLD** (typically 3–4) — concrete fixes needed before merge; unsafe as written but not a one-way door
- **DO NOT MERGE** (typically 1–2) — unmitigated one-way door, breaks downstream consumers without coordination, or fails fundamentally

## Output

```
## <PR title> (#<n>) — <repo>

**Verdict: <SHIP | SHIP WITH MITIGATIONS | HOLD | DO NOT MERGE>** (score: N/10)
<one-line summary>

### Reversibility
<tier>: clean revert | revert + data fix | revert needs migration | one-way door
<One or two sentences. If one-way door: name exactly what cannot be undone and why.>

### Blast radius
<One sentence: who/what is affected, at what scale, if this is wrong. "Every row in `users`" or "all webhook consumers" — not lines-changed.>

### Key risk factors
- [HIGH|MED|LOW] <factor> — <file:line or evidence>

### What the diff doesn't show
<Specific assumptions that, if false, break the PR. "None — change is self-contained" is valid with brief justification.>

### Backwards compatibility
<Does this break callers? Name what breaks and who's affected, or "None observed" with justification.>

### CI & review state
- Checks: <pass/fail summary>
- Reviews: <approvals, requested changes, unresolved threads>
- Mergeable: <mergeStateStatus, conflicts>

### Mitigations to merge with    ← only if SHIP WITH MITIGATIONS
- <flag / rollout / watch / follow-up — specific, addresses a named risk>

### Blockers                     ← only if HOLD or DO NOT MERGE
1. <Specific action with file/area> — addresses <which factor>

### Ship it                      ← only if SHIP
<One line. Note any minor follow-ups as non-blockers.>
```

## Rules (mode-specific)

- Local-branch mode: title `<head-branch> → <base-branch> (local, no PR)`; CI & review section is "no PR yet — not available".
- **Reversibility**, **Blast radius**, and **What the diff doesn't show** are required output sections.
- Monorepos: list affected packages/services, weight by blast radius.
- Say what to test and where — don't suggest generic "add tests".

Shared rules in SKILL.md apply.
