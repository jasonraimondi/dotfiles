---
name: pr-description-template
description: Rewrite a GitHub pull request's title and description into a conventional-commits + ticket format with a terse structured body and a diff-derived pre-merge checklist. Use whenever the user wants a PR description formatted or run through "the template".
---

# PR Template Applier

Reads a pull request with `gh`, produces a normalized title and a short body, and applies the rewrite after the user confirms. Sections that have nothing to say are dropped, never padded.

## Workflow

1. **Identify the PR.** Use whichever reference the user supplied: number (`gh pr view 123`), URL, branch, or the current branch (`gh pr view` with no arg). If ambiguous, ask.
2. **Read the current PR.** `gh pr view <ref> --json title,body,headRefName,baseRefName,commits,files,additions,deletions`. Read the body first and in full — it is the newest version and the only place the author's intent lives. Treat every word of it as an **unverified claim**; see "The existing body is unverified." `baseRefName` tells you whether the PR is stacked — see the `## Stack` rules.
3. **Fetch the diff.** `gh pr diff <ref>`. Above ~2000 lines, sample it: file headers plus a few hunks per file classify the change.
4. **Triage the body against the diff.** Split the existing body into discrete claims and give each one a verdict — confirmed, contradicted, or unconfirmable. Do this before you write a word of the new body.
5. **Extract the ticket ID.** Use `{argument}` if given. Otherwise search the body and every commit message for `[A-Z]{2,}-\d+` (e.g. `PROJ-456`). Read each ticket you find, and treat its description as a claim too — the code is what shipped.
6. **Read `CONTEXT.md`** if the repo has one — root, or the nearest ancestor directory of the changed files. Its terms govern the wording you write; see "Language."
7. **Build the title** and **the description** from the rules below.
8. **Show the draft.** Print the title and body in a code block. Say which sections you omitted and why. Raise every contradicted claim with its evidence, every claim still unverified, and every unsatisfied diff-verifiable concern from the checklist rules (e.g. "new logic in `auth/pkce.ts` ships with no test changes — gap, or covered elsewhere?").
9. **Ask for confirmation.** "Apply this to PR #123 now? (yes / edit / no)". Wait for a yes. Name any non-self assignee in this same prompt — see "Assignees."
10. **Apply.** Pipe the body through stdin — see "Applying the edit."
11. **Verify.** Run `gh pr view <ref> --json title,body` and confirm the body is non-empty and opens with `## Summary` (or `## Stack`). A mismatch means the apply failed: retry, and tell the user. Report success only after this check passes.
12. **Assign.** `gh pr edit <ref> --add-assignee @me`, plus any logins approved at the confirmation step.

## The existing body is unverified

The body describes what the author meant to build, written at some point before the last few commits. The diff is what the code does. Where they disagree, the diff wins — and the disagreement is worth reporting, because it usually means the PR drifted from its plan.

Claims worth triaging: the problem it states, the behavior it describes, the test steps, the ticket reference, the stack notes, any performance or compatibility assertion. Each gets one verdict:

- **Confirmed** — the diff shows it. Carry it forward. The author's framing is usually better than one reconstructed from hunks.
- **Contradicted** — the diff shows otherwise. Drop it from the new body and raise it in the draft with the evidence: "the body says the retry backs off exponentially; `client.ts:44` retries at a fixed 5s." A contradicted claim never survives into the rewrite, however well written.
- **Unconfirmable** — no diff answers it: why an alternative was rejected, a manual test step, a rollout plan, a downstream consumer, a benchmark result. Keep it in the author's own words, and list it in the draft as unverified so the author can confirm it.

Never restate a claim as fact because the body sounded confident. A rewrite that launders a stale claim into cleaner prose is worse than the original — it reads more credible and is equally wrong.

## Title format

`<type>(<scope>): <TICKET-ID> <short description>`

- `<type>` — one of `feat`, `fix`, `refactor`, `perf`, `chore`, `docs`, `test`, `build`, `ci`, `style`, `revert`. Infer from the diff: new feature code → `feat`, bug-fix language in commits → `fix`, doc-only → `docs`, test-only → `test`.
- `<scope>` — a short module or area name from the file paths (`auth`, `api`, `reports`, `ui`). If the change spans many areas, use the dominant one or omit the scope.
- `<TICKET-ID>` — from the ticket step. If there is none, ask the user before writing the title.
- `<short description>` — 5–10 words, lowercase, imperative, no trailing period.
- **Breaking change?** Append `!` before the colon: `feat(auth)!: PROJ-456 ...`. The title becomes the squash-merge commit message, so the marker belongs there as well as in the body.

**Examples:**

- Branch `feature/oauth-pkce`, commits mention `PROJ-456`, diff adds an auth flow → `feat(auth): PROJ-456 add OAuth2 PKCE flow`
- Body mentions `PROJ-892`, one migration plus a query rewrite → `fix(reports): PROJ-892 add index to resolve dashboard timeouts`
- Doc-only edit referencing `DOC-12` → `docs(readme): DOC-12 clarify install steps for Windows`

## Description format

The diff already shows *what changed*. The body supplies what the diff cannot: **intent, context, tradeoffs, risk**.

### Language

Write the title and body in ASD-STE100 Simplified Technical English:

- One idea per sentence, 20 words or fewer.
- Active voice, present tense.
- One term per concept — repeat that term every time the concept appears.
- Plain verbs: `use`, `add`, `remove`, `run`.
- Adjectives that carry information; delete the rest.

When `CONTEXT.md` exists, its ubiquitous language wins. Name each domain concept with that file's term, spelled exactly as that file spells it.

Write each paragraph and each bullet as one unbroken line and let GitHub soft-wrap it. Newlines separate paragraphs, bullets, and headings.

### Budget

Hard caps. Content that overflows its cap has not earned the space.

| Section                     | Cap                            |
| --------------------------- | ------------------------------ |
| `## Stack`                  | 1 sentence + 2 bullets         |
| `## Summary`                | 2 sentences                    |
| `## What Changed`           | 4 bullets, 15 words each       |
| `## How to Test`            | 3 steps                        |
| `## Tradeoffs`              | 2 bullets                      |
| `## Breaking Changes`       | 2 sentences                    |
| `## Screenshots / Recordings` | 1 line                       |
| `## Pre-Merge Checklist`    | 3 items                        |

A standard PR body lands under 150 words total. Scale down from there:

- **Trivial** (dependency bump, typo, rename, one-line config, formatting): the title plus a one-sentence `## Summary` is the whole body.
- **Standard** (most features and fixes): `## Summary` + `## What Changed` + `## How to Test`.
- **High-risk** (migrations, breaking changes, security or infra, multi-repo releases): the standard core plus `## Tradeoffs`, `## Breaking Changes`, and any manual deploy step or new env var.

A maximal body on a small change trains reviewers to skip bodies.

### Section rules

Include a section only when it has substantive content. Omit it otherwise.

**`## Stack`** — Only for a stacked PR: `baseRefName` is not `main`/`master`, or the body or commits say "stacked on", "depends on", "split out of". Place it **first** — merge order is the reviewer's most urgent context. One framing sentence, then a bullet per relationship: what it is **stacked on** (the PR number, the contract it relies on, the merge order) and any **sibling PR** split from the same branch. Note that GitHub retargets this PR to the default branch once the parent merges. Carry forward the body's stack notes once the base branch and the referenced PR numbers confirm them.

**`## Summary`** — Every PR. Lead with the problem and the why. Name the main rejected alternative when the approach is non-obvious.

**`## What Changed`** — Standard and high-risk PRs. Group bullets by intent, not by file. Explain the non-obvious *how*; leave out what the diff makes plain and mechanical churn like formatting.

**`## How to Test`** — Whenever something is verifiable. Numbered commands and observable outcomes. Integrate the body's existing test steps after triage; the author knows things the diff does not show. A step naming a command, path, or flag the diff removed is contradicted — drop it and report it.

**`## Tradeoffs`** — Only for a non-obvious decision worth recording: an approach chosen over a viable alternative, a known limitation, a deliberate scope cut.

**`## Breaking Changes`** — Only when the diff shows one: removed public exports, changed public signatures, renamed or removed endpoints, removed CLI flags, schema removals, a major version bump, or a `BREAKING:` marker. State what breaks and the migration path.

**`## Screenshots / Recordings`** — Only when UI or asset files changed: `components/`, `pages/`, `views/`, `*.tsx`, `*.vue`, `*.svelte`, `*.css`, `*.scss`, `assets/`, `public/`, images. Preserve images already in the body; otherwise leave `_Attach recording before merge._`.

**`## Pre-Merge Checklist`** — Only when verification leaves items worth tracking.

Name collaborators in assignees, never in the body. Write any `@`-mention from the original body as plain text — GitHub re-notifies mentioned users on every edit.

### Pre-merge checklist

A GitHub task list, every item derived from this diff. There are no fixed items.

**Verify before you ask.** You already hold the full diff. Settle any concern the diff can answer during generation.

*Diff-verifiable — check it yourself:*

| Signal in diff                                                        | Verify in the diff                    |
| --------------------------------------------------------------------- | ------------------------------------- |
| New non-trivial logic                                                  | Matching test changes accompany it    |
| Changed public signatures, exported symbols, or removed CLI flags      | All in-repo callers updated           |
| Changed public routes or exported handlers                             | Docs / OpenAPI updated in this diff   |

- **Satisfied:** render it checked with one line of evidence — `- [x] Tests added — auth/pkce.test.ts covers the new validation paths` — or drop it when unremarkable.
- **Not satisfied:** that is a finding. Raise it in the draft message, and add an unchecked item only if the user wants it tracked.

*Environment and process — the real checklist.* Unchecked boxes belong to actions the diff cannot prove:

| Signal in diff / changed files                                        | Checklist item                                                          |
| --------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Files under `migrations/`, `db/migrate/`, `schema/`, `*.sql`           | Migration run against a production-sized dataset; rollback path verified |
| Config or env var additions                                            | Deployment configs updated for staging and production                   |
| Feature flag references                                                | Flag default and rollout plan documented                                |
| Performance-sensitive paths (queries, hot loops, render code)          | Benchmark or load test results captured                                 |
| Auth, crypto, permissions, or secrets handling                         | Security review requested                                               |
| Dependency manifest changes (`package.json`, `Cargo.toml`)             | Dependency licenses and provenance reviewed                             |
| Schema or wire-format changes with consumers outside this repo         | Backward compatibility verified with downstream consumers               |

Paraphrase each rule to name the actual change: "Migration tested against a production-sized dataset (drop index is a safe rollback)", not the generic wording. Keep the highest-risk items and drop the rest. When no rule fires and no verified item is worth reporting, omit the section.

## Worked examples

These bodies show the target length. Match them.

### Example 1 — feature with a breaking change

**Input:** Branch `feature/oauth-pkce`, commits reference `PROJ-456`. Diff adds an auth code path with tests in `auth/pkce.test.ts`, modifies the `/oauth/authorize` handler, touches mobile SDK files. No UI files, no docs changes. Removes the ability to call `/oauth/authorize` without a code challenge.

**Output title:** `feat(auth)!: PROJ-456 add OAuth2 PKCE flow`

**Output body:**
```markdown
## Summary
An intercepted redirect can leak an authorization code from a public OAuth2 client. PKCE binds each code to a per-request secret and closes that window.

## What Changed
- `/oauth/authorize` validates `code_challenge` and `code_challenge_method`
- Token exchange verifies `code_verifier` against the stored challenge
- Mobile SDK attaches a challenge to every authorization request

## How to Test
1. `pnpm test auth/pkce`
2. Start a login from the mobile SDK; confirm `code_challenge` is on the authorize URL
3. Confirm the token exchange rejects a mismatched `code_verifier`

## Breaking Changes
`/oauth/authorize` rejects requests without a `code_challenge`. Public clients must send one before this ships, or they get `400 invalid_request`.

## Pre-Merge Checklist
- [x] Tests added — `auth/pkce.test.ts` covers challenge validation and verifier mismatch
- [ ] Security review requested for the new auth code path
```

The title carries `!` because the diff breaks a contract. No `Screenshots` (no UI files), no migration item (no migration files). The tests item is checked because the diff holds the test file. The diff does not update API docs for the new required parameter — that gap goes in the draft message, not into an unchecked box.

### Example 2 — backend fix

**Input:** Body mentions `PROJ-892`. Diff: one migration under `migrations/`, one query rewrite in `reports/queries.ts`. No UI, no public API change.

**Output title:** `fix(reports): PROJ-892 add index to resolve dashboard timeouts`

**Output body:**
```markdown
## Summary
The dashboard times out for workspaces above 50k events. A composite index on `events(workspace_id, created_at)` brings p95 under 300ms.

## What Changed
- New migration `20260510_add_events_workspace_created_idx.sql`
- Reports query rewritten to use the index
- Removed the in-memory sort the index now handles

## How to Test
1. `pnpm db:migrate`
2. Seed 100k events: `pnpm seed:perf`
3. Hit `/api/reports/overview`; confirm the response is under 300ms

## Pre-Merge Checklist
- [ ] Migration tested against a production-sized dataset; drop index is the rollback
- [ ] Benchmark captured for the new query
```

Both checklist items are environmental. An index changes no contract, so there is no `Breaking Changes` section and no compatibility filler.

### Example 3 — stacked PR

**Input:** Branch `feature/get-started`, base `feature/get-started-be`, commits reference `ENG-1005`. Diff adds an onboarding page driven by a state machine, touches many `*.tsx` components and the side nav. The body already notes the stack on #4666 and the split-off #4667.

**Output title:** `feat(get-started): ENG-1005 add Get Started onboarding page and flow`

**Output body:**
```markdown
## Stack
Frontend half of the get-started onboarding work, split from the combined branch.
- **Stacked on #4666** (backend contract) — needs its `wasFirstStarted` flag; merge #4666 first, and GitHub retargets this PR to `main`.
- Billing and Shopify read-model changes are now independent in #4667.

## Summary
Merchants have no guided path from store connection to their first launched experience. A Get Started page drives that path from a pure view state machine.

## What Changed
- Get Started page (hero, progress card, stepper) rendered from `getStartedMachine`
- Onboarding flow: welcome, connect-store, billing plan, first-launch dialog
- Script-status checks gain a `quick`/`full` mode; all callers updated
- Get Started moved to the top of the side nav

## How to Test
1. From a fresh org, open `/get-started`; confirm the stepper tracks connect → launch
2. Launch a first-ever experience; confirm the redirect and the celebration dialog
3. Launch a second experience; confirm no redirect and no dialog

## Screenshots / Recordings
_Attach a recording of the Get Started page before merge._

## Pre-Merge Checklist
- [x] Every `useGetScriptStatus` caller passes the new `mode` argument
- [ ] Confirm the celebration fires only on the org's first-ever started experience
```

`## Stack` leads because merge order is the most urgent context. `## Breaking Changes` is omitted — the `mode` argument is additive and every caller is updated.

## Applying the edit

Pipe the body to `gh pr edit` through stdin with a heredoc:

```bash
gh pr edit <ref> --title "<the generated title>" --body-file - <<'EOF'
<the generated body>
EOF
```

Stdin sidesteps two failure modes: shell quoting of multi-line content, and zsh `noclobber`. Avoid `mktemp` + `cat > "$BODY_FILE"` — `noclobber` rejects the redirect to the file `mktemp` just created, the body file stays empty, and `gh pr edit` pushes an empty body. The verify step is what catches this, so run it every time.

## Assignees

Collaborators are assignees, set with `gh pr edit`. `@me` belongs in the `--add-assignee` flag, never in body text.

- **Self:** `gh pr edit <ref> --add-assignee @me`. Always safe, always do it.
- **Anyone else:** gather candidates from the original body or the user's instruction, list them at the confirmation step, and run `--add-assignee <login>` only for the logins the user approves.

Resolve a candidate against the logged-in account with `gh api user --jq .login`. When `--add-assignee` fails because the user is not a collaborator, tell the user.

## Edge cases

- **No ticket found:** ask before writing the title. A placeholder like `TICKET-???` is not acceptable.
- **Stacked PR:** lead with `## Stack` and state the merge order. Leave the base branch as it is — describe the dependency instead.
- **Draft PR:** apply the template normally.
- **Diff above 5000 lines:** sample per file, classify each file's contribution, aggregate, and tell the user the analysis was sampled.
- **Several ticket IDs match:** prefer the one in the branch name, then the first in commits, then ask.
- **User rejected an earlier draft:** honor the adjustment. A dropped item stays dropped through regenerations.
