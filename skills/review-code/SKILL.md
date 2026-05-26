---
name: review-code
description: "Unified code-review skill. Seven modes: full (single-pass), security (OWASP-style), architecture (structure/coupling), merge-risk (shippability), adversarial (intent fidelity), caveman (terse comment style), multi (seven reviewers in parallel plus a verifier). Invoke as /review-code <mode> [<scope>]. Use for any code-review or PR-audit task — 'review this PR', 'security review', 'find vulnerabilities', 'architecture review', 'audit against the PR description', 'is this safe to merge', 'multi-agent review', 'deep review', 'caveman review', or /review-code."
license: LICENSE
---

# Code Review

One skill, seven lenses.

| Mode | Question it answers |
|---|---|
| `full` | correctness, security, quality — single pass with a verdict |
| `security` | exploitable OWASP-style vulnerabilities (high-confidence only) |
| `architecture` | module depth, coupling, abstraction boundaries, layering |
| `merge-risk` | shippability and reversibility — SHIP / SHIP WITH MITIGATIONS / HOLD / DO NOT MERGE |
| `adversarial` | did the diff deliver what the stated intent promised |
| `caveman` | terse, no-filler comment style — one line per finding |
| `multi` | seven reviewers in parallel through a verifier — most thorough |

## Dispatch

`/review-code <mode> [<scope>]`. Mode is required; prefer explicit. If the user's phrasing implies a mode ("security review" → `security`, "merge safety" → `merge-risk`, "audit against PR description" → `adversarial`, "thorough review" / "deep review" → `multi`), pick it. If ambiguous, ask.

Scope accepts: PR number, PR URL, branch reference, "this branch" / "my changes", file paths, "these changes". Resolve via the section below.

## Input — resolve scope (all modes)

1. **PR** — `gh pr view <n> --json title,body,baseRefName,headRefName,files,commits` for metadata; `gh pr diff <n>` for the diff.
2. **Branch** — "this branch" / "my changes" with no PR: detect the default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, or `git symbolic-ref refs/remotes/origin/HEAD`); diff against the merge-base: `git diff $(git merge-base HEAD <base>)...HEAD`.
3. **Working tree** — named files or "these changes": `git diff` / `git diff --staged`, or the named files directly.
4. **Unclear** — no PR and a clean working tree: `gh pr list` and ask. Otherwise ask which scope.

Resolve once. In `multi` mode, pass the same resolved scope to every reviewer so they all review the same code.

---

## Mode: `full`

Single-pass review. One read, one report.

**Workflow**
1. Resolve scope.
2. Read changed files in full — surrounding code determines correctness.
3. Walk each change against the checklist; skip dimensions that don't apply.
4. Emit findings grouped by severity, then a verdict.

**Checklist**
- **Correctness** — logic errors, edge cases, off-by-ones, null/undefined paths
- **Security** — injection, auth gaps, secret exposure, unsafe deserialization (for deeper coverage, switch to `security` mode)
- **Breaking changes** — API contracts, removed exports, schema migrations
- **Tests** — new behavior has tests; existing tests aren't weakened
- **Naming & clarity** — variables, functions, types express intent
- **Performance** — unnecessary allocations, N+1 queries, missing indexes

**Output**
```
## <PR title (#n), or branch/scope description>

### Critical
1. file:line — finding

### Suggestions
2. file:line — finding

### Nitpicks
3. file:line — finding

### Verdict
APPROVE | REQUEST_CHANGES | COMMENT — one-sentence rationale
```
Omit empty sections. No filler praise.

**Rules**
- Never approve or submit a review on behalf of the user.
- Flag uncertainty rather than guessing.
- Stay scoped to the diff. Don't review unchanged code unless directly affected.

---

## Mode: `security`

Identify exploitable vulnerabilities. Report only **HIGH-CONFIDENCE** findings — clear vulnerable patterns with attacker-controlled input.

**Scope discipline**
- **Report on**: only the changed code in scope.
- **Research**: the entire codebase to build confidence — trace data flow, check sanitization, check framework protections, check config.

Do not report based on pattern matching alone. Investigate first, then report only what's confirmed exploitable.

**Reference materials**

Detect context from file paths and imports, then load the relevant guides — they carry the patterns to flag and the framework mitigations that produce false positives.

| Code type | References |
|---|---|
| API endpoints, routes | `security/references/authorization.md`, `authentication.md`, `injection.md` |
| Frontend, templates | `security/references/xss.md`, `csrf.md` |
| File handling, uploads | `security/references/file-security.md` |
| Crypto, secrets, tokens | `security/references/cryptography.md`, `data-protection.md` |
| Deserialization | `security/references/deserialization.md` |
| External requests | `security/references/ssrf.md` |
| Business workflows | `security/references/business-logic.md` |
| GraphQL / REST design | `security/references/api-security.md` |
| Config, headers, CORS | `security/references/misconfiguration.md` |
| CI/CD, dependencies | `security/references/supply-chain.md` |
| Error handling | `security/references/error-handling.md` |
| Audit, logging | `security/references/logging.md` |
| Prototype pollution, LLM injection, WebSocket | `security/references/modern-threats.md` |

| Language | Guide |
|---|---|
| Python (Django, Flask, FastAPI) | `security/languages/python.md` |
| JS/TS (Node, Express, React, Vue, Next.js) | `security/languages/javascript.md` |

| Infra | Guide |
|---|---|
| Docker | `security/infrastructure/docker.md` |

**Confidence**

| Level | Criteria | Action |
|---|---|---|
| **HIGH** | Vulnerable pattern + attacker-controlled input confirmed | **Report** with severity |
| **MEDIUM** | Vulnerable pattern, input source unclear | **Note** as "Needs verification" |
| **LOW** | Theoretical, best practice, defense-in-depth | **Do not report** |

In `multi` mode, emit all findings (HIGH/MEDIUM/LOW) with `confidence` set; the verifier filters. In standalone `security` mode, report HIGH only.

**Do not flag**
- Test files (unless reviewing test security)
- Dead / commented code, doc strings
- Server-controlled values (Django settings, env vars, hardcoded constants) — not attacker-controlled
- Framework-mitigated patterns where escaping/parameterization is the default

**Severity**

| Severity | Examples |
|---|---|
| **Critical** | RCE, SQL injection to data, auth bypass, hardcoded secrets |
| **High** | Stored XSS, SSRF to metadata, IDOR to sensitive data |
| **Medium** | Reflected XSS, CSRF on state-changing actions, path traversal |
| **Low** | Missing headers, verbose errors, weak algorithms in non-critical context |

**Always flag (Critical)**
```
eval(user_input)
exec(user_input)
pickle.loads(user_data)
yaml.load(user_data)              # not safe_load
unserialize($user_data)
deserialize(user_data)
shell=True + user_input
child_process.exec(user)
```

**Always flag (High)**
```
innerHTML = userInput              # DOM XSS
dangerouslySetInnerHTML={user}     # React XSS
v-html="userInput"                 # Vue XSS
f"SELECT * FROM x WHERE {user}"    # SQL injection
os.system(f"cmd {user_input}")     # Command injection
```

**Output**
```
## Security Review: <File/Component Name>

### Summary
- **Findings**: X (Y Critical, Z High, ...)
- **Risk Level**: Critical/High/Medium/Low

### Findings

#### [VULN-001] <Vulnerability Type> (Severity)
- **Location**: `file.py:123`
- **Confidence**: High
- **Issue**: <what>
- **Impact**: <what an attacker could do>
- **Evidence**:
  ```python
  <vulnerable code snippet>
  ```
- **Fix**: <how to remediate>

### Needs Verification
- **Location**: `file.py:456`
- **Question**: <what needs to be verified>
```

If nothing found: "No high-confidence vulnerabilities identified."

---

## Mode: `architecture`

Single-pass through one lens: did this change make the codebase's structure better or worse? Not correctness, not security — structure and design quality.

A **deep module** (Ousterhout, *A Philosophy of Software Design*) hides a large implementation behind a small interface. Shallow modules, leaky boundaries, and tight coupling are the friction this mode surfaces.

**Workflow**
1. Resolve scope.
2. Read changed files in full, **plus their callers** — architecture lives in the seams; a diff alone hides coupling.
3. Analyze each change against the checklist.
4. Emit findings grouped by severity, then a verdict.

**Checklist**
- **Module depth** — new modules whose interface is nearly as complex as their implementation; pass-through wrappers
- **Coupling** — new dependencies between modules that shouldn't know about each other; one concept spread thin
- **Abstraction boundaries** — interfaces leaking implementation detail; callers forced to know internals
- **Layering** — direction-of-dependency violations (domain importing infra, UI reaching into persistence)
- **Responsibility placement** — logic bolted onto a convenient caller instead of the owning module
- **Testability at the seam** — can the new behavior be tested at the module boundary?
- **Speculative structure** — abstractions with a single caller and no concrete second use
- **Naming & clarity** — names express intent; control flow followable without tracing every branch
- **Dead weight** — code, exports, parameters left unused

**Output**
```
## <PR title (#n), or branch/scope description>

### Critical
1. file:line — finding

### Suggestions
2. file:line — finding

### Nitpicks
3. file:line — finding

### Verdict
APPROVE | REQUEST_CHANGES | COMMENT — one-sentence rationale
```

Each finding names the structural problem *and* the cheaper shape — not just "this is coupled".

**Rules**
- Stay scoped. Pre-existing problems are out of scope unless the change makes them worse.
- Propose the smaller-interface alternative concretely; flag uncertainty rather than guessing.

---

## Mode: `merge-risk`

Conservative merge verdict with explicit reversibility analysis. **Reversibility is load-bearing** — a 5,000-line PR of pure additions to a new service can be safer than a 20-line PR that drops a column. **One-way doors** (irreversible actions) are the single biggest risk multiplier.

**Workflow**
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

**Reversibility tiers**
- **Clean revert** — revert and you're back to safe. Most code-only changes.
- **Revert + data fix** — revert plus a small, well-understood one-time correction (backfill, replay).
- **Revert needs a migration** — undoing requires a forward fix; recoverable but not instant.
- **One-way door** — irreversible: destructive DDL, public API removal once consumers adapt, key rotations once distributed, sent emails/notifications, processed payments, external side effects, removed feature flags whose code paths are gone.

**Risk signals (subtract from 10)**

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

**Verdict tiers** (verdict primary; score secondary)
- **SHIP** (typically 8–10) — clean revert, no HIGH factors, CI green, reviews satisfied
- **SHIP WITH MITIGATIONS** (typically 5–7) — proceed *with* a specific mitigation (flag, staged rollout, dashboard watch, named follow-up). Generic "monitor closely" is not a mitigation.
- **HOLD** (typically 3–4) — concrete fixes needed before merge; unsafe as written but not a one-way door
- **DO NOT MERGE** (typically 1–2) — unmitigated one-way door, breaks downstream consumers without coordination, or fails fundamentally

**Output**
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

**Rules**
- Cite `file:line` for every code-level risk claim.
- Local-branch mode: title `<head-branch> → <base-branch> (local, no PR)`; CI & review section is "no PR yet — not available".
- **Reversibility**, **Blast radius**, and **What the diff doesn't show** are required output sections.
- Monorepos: list affected packages/services, weight by blast radius.
- Say what to test and where — don't suggest generic "add tests".
- **Never run** `gh pr review`, `gh pr comment`, `gh pr merge`, `gh pr approve`.

---

## Mode: `adversarial`

Single-pass through one lens: did the diff actually deliver what the stated intent claimed? Not correctness, not structure — intent fidelity.

The implementer has rationalizations baked into their session ("I did it this way because…"). A fresh adversarial reader doesn't share those and is more likely to notice what was skipped, hand-waved, or quietly descoped.

**Stated intent**

Where the contract lives depends on scope:
- **PR** — title + body + commit messages
- **Branch** — commit messages plus any plan/task doc passed in scope
- **Working tree** — any plan/task doc passed in scope (if none, say so and stop — don't audit against an invented contract)

**Workflow**
1. Read the stated intent in full. Bullet out every promised behavior, named verification step, named interface, listed scope item, acknowledged edge case.
2. Read the diff in full, tests included.
3. **For each intent bullet** — locate the code that delivers it. Not present = gap.
4. **For each diff hunk** — locate the intent bullet that justifies it. Unjustified = scope creep.
5. **For each test** — mentally revert the change being tested. Would the test still pass? Yes = vacuous.
6. Emit findings grouped by severity, then a verdict.

**Checklist**
- **Descoped item** — intent promises X; diff doesn't deliver X.
- **Vacuous test** — passes with the change reverted.
- **Skipped verification** — intent names a verification step ("verified with curl", "tested race condition", "ran the migration in staging") but the diff has no test, log, or evidence.
- **Interface drift** — intent specifies signature, endpoint, schema, or config key; diff implements differently without rationale.
- **Hand-waved error path** — intent acknowledges an error path; diff swallows it, logs without recovery, or doesn't address it.
- **Scope creep** — code the intent doesn't justify (especially: expands public interface, changes unrelated behavior, quietly couples in new deps).
- **Renamed without justification** — names, paths, constants, env vars drifted from the plan with no explanation.

**Output**
```
## <PR title (#n), or branch/scope description>

### Stated intent
- bullet 1 (source: PR body L12)
- bullet 2 (source: commit abc1234)

### Critical (descoped items, vacuous tests on the core fix)
1. **[Descoped]** Intent says "validate webhook signature" (PR body L8); diff has no signature check — searched handler.py and middleware.py.

### Suggestions (scope creep, drift, soft gaps)
2. **[Drift]** Plan calls for `fetch(url, opts)`; diff has `fetch(url, opts, retries)` — extra parameter undocumented.

### Nitpicks
3. **[Rename]** Plan refers to `user_id`; diff uses `uid` in three new functions.

### Verdict
ALIGNED | GAPS | DRIFT — one-sentence summary of intent-vs-implementation fit
```

Omit empty sections. Every finding names **both halves**: the intent bullet *and* the missing/divergent code.

**Rules**
- Don't critique the intent itself; audit only whether the diff matches it.
- Don't flag missing features that weren't promised. Don't construct attack scenarios. Don't suggest design improvements.
- Adversarial stance — assume hand-waving until proven otherwise.
- If no stated intent is available, say so and stop. Don't invent a contract.
- Never approve or submit a review on behalf of the user.

---

## Mode: `caveman`

Style guide for terse review comments. One line per finding. Location, problem, fix. No throat-clearing.

`L<line>: <problem>. <fix>.` — or `<file>:L<line>: ...` for multi-file diffs.

**Severity prefix (when mixed)**
- `🔴 bug:` — broken behavior, will cause incident
- `🟡 risk:` — works but fragile (race, missing null check, swallowed error)
- `🔵 nit:` — style, naming, micro-optim — author can ignore
- `❓ q:` — genuine question, not a suggestion

**Drop**
- "I noticed that…", "It seems like…", "You might want to consider…"
- "This is just a suggestion but…" — use `nit:` instead
- "Great work!" / "Looks good overall but…" — say it once at top, not per comment
- Restating what the line does — reviewer reads the diff
- Hedging ("perhaps", "maybe", "I think") — if unsure, use `q:`

**Keep**
- Exact line numbers
- Exact symbol/function/variable names in backticks
- Concrete fix, not "consider refactoring this"
- The *why* if the fix isn't obvious from the problem statement

**Examples**

❌ "I noticed that on line 42 you're not checking if the user object is null…"
✅ `L42: 🔴 bug: user can be null after .find(). Add guard before .email.`

❌ "It looks like this function is doing a lot of things…"
✅ `L88-140: 🔵 nit: 50-line fn does 4 things. Extract validate/normalize/persist.`

❌ "Have you considered what happens if the API returns a 429?"
✅ `L23: 🟡 risk: no retry on 429. Wrap in withBackoff(3).`

**Drop terse mode for**
- Security findings — CVE-class bugs need full explanation
- Architectural disagreements — need rationale
- Onboarding contexts — when the author needs the *why*

In those cases, write a paragraph, then resume terse for the rest.

**Boundaries**

Reviews only. Doesn't write the code fix, doesn't approve / request changes, doesn't run linters. Output the comment(s) ready to paste into the PR.

---

## Mode: `multi`

Seven reviewers fan out in parallel; an eighth verifies every finding against the source. Cuts single-pass blind spots and surfaces only verified findings.

Roles split on purpose: **correctness** and **architecture** separate logic from structure, a dedicated **security** pass runs OWASP-style, a **tests** reviewer checks the tests would fail if the bug were present, an **adversarial** pass audits the diff against its stated intent (descoped items, vacuous tests, interface drift), **merge risk** scores shippability, and a **caveman** reads the whole change terse and unscoped.

### Finding schema

Each of Agents 1–6 returns a JSON object with a `findings` array. `{"findings": []}` means the reviewer ran and found nothing; a missing or malformed response means the reviewer failed.

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

### Step 1 — Dispatch reviewers in parallel

Resolve scope once (see Input), then dispatch all seven Agent calls in a **single message** — separate messages run sequentially. Pass the resolved scope verbatim to every reviewer **and to the verifier** so they all review the same code.

| # | Agent | Skill to invoke | Focused scope |
|---|---|---|---|
| 1 | correctness | `/review-code full` | logic bugs, races, error handling, data loss, broken contracts |
| 2 | security | `/review-code security` | OWASP-style; emit all findings with `confidence` set; do **not** pre-filter |
| 3 | architecture | `/review-code architecture` | module depth, coupling, abstraction boundaries, layering, testability at the seams, naming/clarity, dead code, speculative structure |
| 4 | caveman | `/review-code caveman` | unscoped: anything across correctness, security, design, maintainability — terse, surface what looks worst |
| 5 | tests | `testing-tdd` (external skill) | do the tests exercise the risky and changed paths; would each test still pass if the bug were present; assertions specific; missing cases for new branches and error paths |
| 6 | adversarial | `/review-code adversarial` | audit the diff against its stated intent: descoped items, vacuous tests, skipped verification, interface drift, scope creep |
| 7 | merge risk | `/review-code merge-risk` | verdict (SHIP / SHIP WITH MITIGATIONS / HOLD / DO NOT MERGE), reversibility, blast radius, key risk factors, BC, CI/review state |

Every reviewer prompt includes:
1. **Review scope** — resolved scope, passed verbatim so every reviewer reviews the same code.
2. **Focused scope** — the row's "focused scope" cell; don't widen. Adapt findings to the change's language.
3. **Skill to invoke** — via the Skill tool before reviewing (this skill in a specific mode, or the named external skill).
4. **Output** — Agents 1–6: JSON per the schema above (Agent 5: `category: "correctness"` for a test that would not catch the bug, `category: "maintainability"` for missing coverage; Agent 6: pick the category that fits the gap — `correctness` for missing feature/broken contract, `maintainability` for vacuous tests or skipped verification, `design` for interface drift). Agent 7: return its native report verbatim.

Agent 7's SHIP/HOLD verdict is qualitative and passes through unchanged — not re-scored. Its factual claims ("breaks BC", "blast radius: auth path", CI/review state) are checkable; the verifier fact-checks them in Step 2.

### Step 2 — Verifier (sequential, after fan-out completes)

Dispatch an eighth Agent. Give it the resolved scope (verbatim, as passed to the reviewers — it needs this to open files at the correct ref), the six reviewer finding lists (Agents 1–6), and Agent 7's report.

For each finding:
1. Open the cited file at the resolved scope and confirm the code matches the claim. For adversarial findings (Agent 6), confirm both halves — the stated intent (PR description, commit message, plan doc) really says what the agent claims it says, and the diff really does/doesn't deliver what the agent claims. A gap counts only if both sides verify; an imagined requirement gets dropped.
2. Drop findings that don't verify. Weight `confidence`: a `low`-confidence finding survives only with clear, quoted code evidence. Security and adversarial findings below `high` confidence survive only if verification independently confirms them — filtering happens here, not at the reviewer, since verification is what promotes a real medium-confidence finding and kills a hallucinated high-confidence one.
3. Group findings at the same root cause; preserve each distinct framing (a line flagged for both a race and a coupling problem keeps both) — link, don't collapse.
4. Where the fix is small and unambiguous, draft the diff — the files are already open.

Then **fact-check Agent 7**: for each factual claim in its report (BC, blast radius, CI/review state), confirm it against the diff. Flag any claim that doesn't hold; leave the SHIP/HOLD verdict itself unchanged.

Then categorize each surviving finding against this bar:
- **critical** — blocks merge: correctness, security, data loss, broken contract, test that would not catch a regression on a risky path
- **suggestion** — worth raising, doesn't block
- **nit** — style or preference

Then rate the engineering quality of the change:
- **overengineered** — speculative abstractions, unused flexibility, premature generalization, error handling for impossible cases, more code than the problem needs
- **underengineered** — missing validation at real boundaries, no tests for risky paths, ignored edge cases, shortcuts that will break
- **perfectly engineered** — scope matches the problem; no speculative scaffolding and no missing safeguards

Justify in 1–2 sentences citing specific **verified findings** (not unverified claims or the raw diff).

### Final output

1. **Summary** — what the change does, grounded in the diff. If Agent 6 surfaced an intent-vs-implementation gap (descoped item, vacuous test, interface drift), state it here.
2. **Merge risk** — verdict and reversibility from Agent 7, followed by its key risk factors. Pass through Agent 7's report verbatim where useful; note any claim the verifier flagged as unconfirmed.
3. **Engineering quality** — rating (overengineered / underengineered / perfectly engineered) + 1–2 sentence justification.
4. **Findings** grouped by severity, each with `file:line`, claim, and the verifier's drafted diff where one exists.

### Rules (multi mode)

- Never approve, comment on, or merge the PR.
- If a reviewer fails or returns nothing, note it in the summary; don't silently drop.
- The verifier fact-checks Agent 7's claims but does not re-derive the SHIP/HOLD verdict.
