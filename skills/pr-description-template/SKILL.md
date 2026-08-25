---
name: pr-description-template
description: Rewrite a GitHub pull request's title and description into a conventional-commits + ticket format with a terse structured body and a diff-derived pre-merge checklist. Use whenever the user wants a PR description formatted or run through "the template".
disable-model-invocation: true
---

# PR Template Applier

Reads a pull request with `gh`, writes a normalized title and a short body, and applies them. A section waits for its trigger; a section with nothing to say never appears.

## Workflow

1. **Identify the PR.** Use whichever reference the user supplied: number (`gh pr view 123`), URL, branch, or the current branch (`gh pr view` with no arg). If ambiguous, ask.
2. **Gather.** `gh pr view <ref> --json title,body,headRefName,baseRefName,commits,files,additions,deletions` and `gh pr diff <ref>`. Read the body first and in full — it is the newest version and the only place the author's intent lives. `baseRefName` tells you whether the PR is stacked. Above ~2000 diff lines, sample it: file headers plus a few hunks per file classify the change.
3. **Triage the body against the diff.** See "Triage the body".
4. **Read the ticket and `CONTEXT.md`.** Use `{argument}` for the ticket if given; otherwise search the body and every commit message for `[A-Z]{2,}-\d+` (e.g. `PROJ-456`). Read each ticket you find and treat its description as a claim too — the code is what shipped. Read `CONTEXT.md` if the repo has one (root, or the nearest ancestor directory of the changed files); its terms govern the wording you write.
5. **Build the title and the body** from the rules below.
6. **Apply.** Pipe the body through stdin — see "Applying the edit". Apply as soon as it is written; `gh pr edit` is re-runnable, so a rewrite the user dislikes costs one more run.
7. **Verify.** Run `gh pr view <ref> --json title,body` and confirm the body is non-empty and opens with `## Summary` (or `## Stack`). A mismatch means the apply failed: retry, and tell the user. Report success only after this check passes.
8. **Assign.** `gh pr edit <ref> --add-assignee @me`, plus any login the user named in their instruction.
9. **Report.** Print the applied title and body in a code block, then only what needs the user's judgment: every contradicted claim with its evidence, every claim still unverified, and every gap from the diff audit. When the diff spans unrelated top-level areas, add one line suggesting the PR be split.

## Triage the body

The body is what the author meant to build; the diff is what the code does. Split the body into discrete claims and give each one a verdict before writing a word of the new body.

- **Confirmed** — the diff shows it. Carry it forward in the author's framing, which usually beats one reconstructed from hunks.
- **Contradicted** — the diff shows otherwise. Drop it, and raise it in the report with the evidence: "the body says the retry backs off exponentially; `client.ts:44` retries at a fixed 5s."
- **Unconfirmable** — no diff answers it: a rollout plan, a benchmark result, why an alternative lost. Keep the author's own words and list it in the report as unverified.

A rewrite that launders a stale claim into cleaner prose reads more credible and is equally wrong.

## Title format

`<type>(<scope>): <TICKET-ID> <short description>`

- `<type>` — one of `feat`, `fix`, `refactor`, `perf`, `chore`, `docs`, `test`, `build`, `ci`, `style`, `revert`. Infer from the diff: new feature code → `feat`, bug-fix language in commits → `fix`, doc-only → `docs`, test-only → `test`.
- `<scope>` — a short module or area name from the file paths (`auth`, `api`, `reports`, `ui`). If the change spans many areas, use the dominant one or omit the scope.
- `<TICKET-ID>` — from step 4. When no ticket ID appears in the branch, body, or commits, leave it out: `fix(reports): rewrite dashboard query`.
- `<short description>` — 5–10 words, lowercase, imperative, no trailing period.
- **Breaking change?** Append `!` before the colon: `feat(auth)!: PROJ-456 add OAuth2 PKCE flow`. The title becomes the squash-merge commit message, so the marker belongs there as well as in the body.

## Description format

The diff already shows *what changed*. The body supplies what the diff cannot: **intent, context, risk**.

### Language

Write in ASD-STE100 Simplified Technical English: one idea per sentence, 20 words or fewer, active voice, present tense, one term per concept, plain verbs. When `CONTEXT.md` exists, its ubiquitous language wins — spell each domain concept exactly as that file spells it.

Write each paragraph and each bullet as one unbroken line and let GitHub soft-wrap it. Newlines separate paragraphs, bullets, and headings.

### Sections

In this order. The typical PR body is a title and three sentences; every other section waits for its trigger.

**`## Stack`** — Only when `baseRefName` is not `main`/`master`, or the body or commits say "stacked on", "depends on", "split out of". First position: merge order is the reviewer's most urgent context. One framing sentence and at most 2 bullets — what it is **stacked on** (the PR number, the merge order) and any **sibling PR** split from the same branch. Note that GitHub retargets this PR to the default branch once the parent merges.

**`## Summary`** — Every PR. Three sentences of prose, no bullets: the problem, the approach, and the main rejected alternative when the approach is non-obvious. On a typical PR this section is the whole body.

**`## Breaking Changes`** — Only when the diff shows one: removed public exports, changed public signatures, renamed or removed endpoints, removed CLI flags, schema removals, a major version bump, or a `BREAKING:` marker. Two sentences: what breaks, and the migration path.

**`## Pre-Merge Checklist`** — See "Pre-merge checklist". At most 2 items, all unchecked.

**`## Screenshots`** — Only when the original body already holds images or video links. Carry them through unchanged, at the bottom. Generate nothing here.

Name collaborators in assignees. Write any `@`-mention from the original body as plain text — GitHub re-notifies mentioned users on every edit.

### Pre-merge checklist

A GitHub task list. Every item is **a human action, before merge, that CI cannot perform, made necessary by this diff.** An action CI can prove is not an item.

Signals that usually produce one:

| Signal in the diff                                              | Item                                                                    |
| --------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Files under `migrations/`, `db/migrate/`, `schema/`, `*.sql`     | Migration run against a production-sized dataset; rollback path verified |
| Schema or wire-format change with consumers outside this repo    | Backward compatibility confirmed with downstream consumers               |
| Auth, crypto, permissions, or secrets handling                   | Security review requested                                                |
| Feature flag references                                          | Flag default and rollout plan documented                                 |
| New env vars or config keys                                      | Deployment configs updated for staging and production                    |
| Behavior only a human can confirm (visual, timing, first-run)    | The exact thing to click through and observe                             |

Paraphrase each item to name the actual change: "Migration tested against a production-sized dataset (drop index is a safe rollback)", not the generic wording. Keep the two highest-risk items. Most PRs fire nothing — then the section is omitted.

### Diff audit

You hold the full diff, so settle these yourself during generation. Findings go in the report, never in the body.

| Signal in the diff                                                | Verify in the diff                  |
| ------------------------------------------------------------------ | ----------------------------------- |
| New non-trivial logic                                              | Matching test changes accompany it  |
| Changed public signatures, exported symbols, or removed CLI flags  | All in-repo callers updated         |
| Changed public routes or exported handlers                         | Docs / OpenAPI updated in this diff |

A gap is a question for the chat: "new logic in `auth/pkce.ts` ships with no test changes — gap, or covered elsewhere?" It reaches the body as a checklist item only when the user asks to track it.

## Worked examples

### Example 1 — the typical PR

**Input:** Body mentions `PROJ-892`. Diff: one query rewrite in `reports/queries.ts`. No migration, no UI, no public API change.

**Output title:** `fix(reports): PROJ-892 rewrite dashboard query to use the events index`

**Output body:**
```markdown
## Summary
The dashboard times out for workspaces above 50k events. The reports query now drives off the existing `events(workspace_id, created_at)` index instead of sorting in memory. A materialized rollup was rejected: it adds a refresh path for a query that is fast enough once indexed.
```

That is the whole body. No migration files, so no checklist. No contract change, so no `Breaking Changes`. Most PRs look like this.

### Example 2 — the rare maximum

**Input:** Branch `feature/oauth-pkce`, base `feature/oauth-be`, commits reference `PROJ-456`. Diff adds an authorization code path with tests in `auth/pkce.test.ts`, modifies the `/oauth/authorize` handler, removes the ability to call it without a code challenge, and adds an `OAUTH_PKCE_REQUIRED` env var.

**Output title:** `feat(auth)!: PROJ-456 add OAuth2 PKCE flow`

**Output body:**
```markdown
## Stack
Client half of the PKCE work, split from the combined branch.
- **Stacked on #4666** (token-exchange contract) — merge #4666 first, and GitHub retargets this PR to `main`.

## Summary
An intercepted redirect can leak an authorization code from a public OAuth2 client. PKCE binds each code to a per-request secret, so a stolen code is useless without the verifier. Rotating codes on redirect was rejected: it closes a smaller window and still trusts the redirect.

## Breaking Changes
`/oauth/authorize` rejects requests without a `code_challenge`. Public clients must send one before this ships, or they get `400 invalid_request`.

## Pre-Merge Checklist
- [ ] Security review requested for the new authorization code path
- [ ] `OAUTH_PKCE_REQUIRED` set in staging and production before deploy
```

Four sections is the ceiling, and it takes a stacked base, a broken contract, and two real human actions to reach it. The diff holds `auth/pkce.test.ts`, so the audit passes and nothing about tests reaches the body. The diff does not update the API docs for the new required parameter — that goes in the report, not into a box.

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
- **Anyone else:** run `--add-assignee <login>` only for a login the user named in their instruction. An assignment notifies that person, so a name found in the original body is a suggestion for the report, not an assignment.

Resolve a candidate against the logged-in account with `gh api user --jq .login`. When `--add-assignee` fails because the user is not a collaborator, tell the user.

## Edge cases

- **No ticket found:** leave the ticket ID out of the title and write the rest of it normally.
- **Diff above 5000 lines:** sample per file, classify each file's contribution, aggregate, and tell the user the analysis was sampled.
- **Several ticket IDs match:** prefer the one in the branch name, then the first in commits.
- **User wants a change after the apply:** honor the adjustment and re-apply. A dropped item stays dropped through later rewrites.
