---
name: pr-merge-risk
description: "Score a GitHub pull request's merge risk on a 1-10 scale (10 = safest) with concrete reasons and remediation steps. Use when the user says: merge risk, risk to merge, merge safety, risk score, is this PR safe to merge, should I merge this, /pr-merge-risk, or provides a GitHub PR URL/number and asks about merge safety."
---

# PR Merge Risk

Analyze a pull request and produce a conservative merge-risk score with specific, actionable remediation. **Analysis only** — never approve, comment on, or merge the PR.

## Input

Accept any of: full GitHub PR URL, `owner/repo#123`, `#123` (current repo), or bare PR number. If ambiguous, run `gh pr list` and ask which one.

Do NOT recommend `/ultrareview` — that is a separate user-triggered billed action.

## Workflow

1. **Read intent first**: PR title, body, and linked issues. If the description is empty or unclear, record it as a risk signal but proceed.
2. **Gather** (run in parallel where possible; for cross-repo PRs add `--repo owner/repo` to each command):
   - `gh pr view <n> --json title,body,baseRefName,headRefName,author,isDraft,mergeable,mergeStateStatus,reviewDecision,reviews,files,additions,deletions,labels,createdAt,updatedAt`
   - `gh pr diff <n>`
   - `gh pr checks <n>`
   - `gh pr view <n> --comments` for review threads (resolved + unresolved)
3. **Read changed files in full** for high-risk hits — migrations, auth/session/crypto, public API surfaces, config, infra/IaC. Don't trust a diff in isolation; surrounding code determines blast radius.
4. **Score** against the rubric below. Start at 10 and stack deductions across categories; cap each category at its listed range; floor at 1. Be conservative: when uncertain, score lower and explain.
5. **Sanity-check**: if any factor is HIGH severity, the final score should rarely exceed 6. If it does, recalibrate before emitting.
6. **Emit** the report in the exact output format below.

## Risk Signals (subtract from 10)

Severity in parens is the typical deduction; adjust based on blast radius.

- **Backwards compatibility** (−2 to −4): removed/renamed public APIs, changed signatures, removed exports, removed config keys, renamed env vars, response-shape changes, removed fields/columns
- **Destructive migrations** (−2 to −4): `DROP`, `ALTER COLUMN`, adding `NOT NULL` to existing tables, renames, large backfills, anything irreversible
- **Config / feature flags** (−1 to −3): default flips, removed flags, flag-gated paths reaching prod without rollout plan
- **Dependencies** (−1 to −3): major version bumps, new deps without prior usage, lockfile-only changes that imply transitive shifts
- **Security-sensitive areas** (−2 to −4): auth, authz, session, crypto, secrets, input parsing, deserialization, SSRF surfaces
- **Test coverage** (−1 to −3): new code with no tests, removed/skipped tests, integration-only paths with mocked DB
- **Size & scope** (−1 to −2): >500 LOC, multiple unrelated changes, touches many packages in a monorepo
- **CI** (−1 to −4): failing required checks, missing checks, flaky required check freshly skipped
- **Mergeability** (−1 to −2): `mergeStateStatus` not `CLEAN` — flag `DIRTY` (conflicts), `BEHIND` (stale base), `BLOCKED` (missing reviews/checks), `UNSTABLE` (non-required check failing)
- **Meta** (−1 to −2): empty/missing PR description, draft, author's first PR to this area, end-of-week or near-release timing
- **Blast radius (monorepo)** (−1 to −3): touches shared libs, public packages, infra, deployment configs

A PR may legitimately score 10 (small, tested, reviewed, green CI, no breaking surface).

## Output Format

```
## <PR title> (#<n>) — <repo>

**Risk score: N/10** — <one-line summary>

### Key risk factors
- [HIGH|MED|LOW] <factor> — <file:line or evidence>
- ...

### Backwards compatibility
<Explicit: does this break existing callers, consumers, or clients? Name what breaks and who's affected. "None observed" is a valid answer with brief justification.>

### CI & review state
- Checks: <pass/fail summary>
- Reviews: <approvals, requested changes, unresolved threads>
- Mergeable: <mergeStateStatus, conflicts>

### What to do before merging   ← only if score < 7
1. <Specific action with file/area> — addresses <which factor>
2. ...

### Ship it   ← only if score >= 7
<One line. Note any minor follow-ups as non-blockers.>
```

## Rules

- Cite `file:line` for every code-level risk claim. Vague claims aren't useful.
- Empty PR description is itself a risk signal — call it out.
- For monorepos, list affected packages/services and weight by blast radius.
- Don't suggest generic advice ("add tests"). Say what to test, where.
- **Never run** `gh pr review`, `gh pr comment`, `gh pr merge`, or `gh pr approve`.
