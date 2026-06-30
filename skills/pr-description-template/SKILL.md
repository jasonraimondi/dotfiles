---
name: pr-description-template
description: Read an open GitHub pull request via the `gh` CLI and rewrite its title and description to follow a conventional-commits + JIRA-ticket format with a concise structured body and a smart pre-merge checklist derived from the diff. Use this skill whenever the user wants to clean up, format, normalize, standardize, or apply a template to a pull request — including phrases like "fix my PR description" or "update PR".
---

# PR Template Applier

Reads a GitHub pull request and produces a normalized title and description following a fixed template, then offers to apply the rewrite via `gh pr edit`. The body stays concise — sections that don't apply are dropped entirely rather than padded with "N/A".

## When to use

Trigger this skill whenever the user wants their PR formatted, normalized, cleaned up, or run through "the template." The user will usually reference a PR number, branch, or URL. If none is provided, ask which PR to act on.

## Workflow

Follow these steps in order. Don't skip the confirmation step at the end — the user explicitly wants to review the draft before anything is pushed.

1. **Identify the PR.** Use whichever the user supplied: number (`gh pr view 123`), URL (pass to `gh pr view`), branch (`gh pr view <branch>`), or the current branch (`gh pr view` with no arg). If ambiguous, ask.
2. **Fetch the data.** Run `gh pr view <ref> --json title,body,headRefName,baseRefName,commits,files,additions,deletions`. This single call returns everything needed. `baseRefName` tells you whether the PR targets the default branch or is stacked on another branch (see the `## Stack` rules).
3. **Fetch the diff for smart todos.** Run `gh pr diff <ref>`. If the diff is large (>2000 lines), truncate sensibly — file headers and a sample of hunks per file is enough to classify changes.
4. **Extract the ticket ID.** A ticket may be provided by {argument}, if not search the PR body and each commit message for a `[A-Z]{2,}-\d+` pattern (e.g., `PROJ-456`, `JIRA-1234`). If found, read each one.
5. **Build the title** following the format below.
6. **Build the description** following the section rules below.
7. **Show the draft to the user.** Display the proposed title and body in a code block. State clearly which sections were omitted and why (e.g., "no breaking changes detected, omitting that section"), and raise any unsatisfied diff-verifiable concerns found while building the checklist (e.g., "new logic in `auth/pkce.ts` has no accompanying test changes — gap, or covered elsewhere?").
8. **Ask for confirmation.** Ask the user something like: "Apply this to PR #123 now? (yes / edit / no)". Wait for an affirmative response. **Assignees:** the current logged-in GitHub user is assigned automatically and needs no confirmation. If you would assign anyone else (a name pulled from the original body or the user's request), name those users in this same prompt and get explicit approval before assigning them — see "Assigning the PR."
9. **Apply on confirmation.** Pipe the body to `gh pr edit --body-file -` via a heredoc (see "Applying the edit" below). Do **not** use `mktemp` + `cat >` — zsh's `noclobber` makes that redirect fail silently and you'll push an empty body.
10. **Verify the apply.** Immediately after `gh pr edit`, run `gh pr view <ref> --json title,body` and confirm the body is non-empty and starts with `## Summary` (or `## Stack` for a stacked PR). If it doesn't match, the apply failed — retry and surface the failure to the user. Never claim success without this check.
11. **Assign the PR.** Assign the current user with `gh pr edit <ref> --add-assignee @me`. Assign any *other* users only after the explicit approval from step 8: `gh pr edit <ref> --add-assignee <login>`. Never assign a user other than the logged-in one without asking first. See "Assigning the PR."

## Title format

Always use: `<type>(<scope>): <TICKET-ID> <short description>`

Where:
- `<type>` is one of: `feat`, `fix`, `refactor`, `perf`, `chore`, `docs`, `test`, `build`, `ci`, `style`, `revert`. Infer from the diff: new feature code → `feat`, bug fix language in commits/body → `fix`, doc-only changes → `docs`, test-only → `test`, and so on.
- `<scope>` is a short module/area name inferred from the file paths (e.g., `auth`, `api`, `reports`, `ui`). If changes span many areas, pick the dominant one or omit the scope.
- `<TICKET-ID>` is the ticket extracted in step 4. If unavailable, ask the user — don't proceed without it.
- `<short description>` is 5–10 words, lowercase, imperative mood, no trailing period.

**Examples:**

- Input branch `feature/oauth-pkce`, commits mention `PROJ-456`, changes add new auth flow → `feat(auth): PROJ-456 add OAuth2 PKCE flow`
- Input body mentions `PROJ-892`, single migration + query rewrite → `fix(reports): PROJ-892 add index to resolve dashboard timeouts`
- Doc-only edit referencing `DOC-12` → `docs(readme): DOC-12 clarify install steps for Windows`

## Description format

Use Markdown. Include sections **only if they have substantive content**. Omit entirely otherwise — don't write "None" or "N/A".

### Section rules

**`## Stack`** — Include **only if** the PR is part of a stack: it targets a non-default base branch (`baseRefName` is not `main`/`master`), or the body/commits reference other PRs with stacking language ("stacked on", "depends on", "split out of"). Place it **first**, above `## Summary` — merge order is the reviewer's most urgent context. Write one short framing sentence (what this PR is relative to the larger effort), then a bullet per relationship:
- What it's **stacked on** — the dependency PR (`#1234`), the contract/change it relies on, and the merge order ("merge #1234 first"). Note that GitHub auto-retargets this PR to the default branch once the parent merges.
- **Sibling PRs** split from the same branch that are now independent.

Preserve any stack notes already in the body. If the PR targets the default branch and nothing references another PR, omit this section entirely.

**`## Summary`** — Always include. 1–2 sentences explaining what the PR does and why it matters. No fluff, no restating the title.

**`## What Changed`** — Always include. Bullet list of the meaningful changes (3–6 bullets typical). Group related changes into one bullet rather than listing every file. Skip purely mechanical changes (formatting, import sorting) unless they're the point of the PR.

**`## How to Test`** — Always include. Numbered list of concrete verification steps. Prefer commands and observable outcomes over vague directions. If the original PR body has test instructions, integrate them; don't discard the author's domain knowledge.

**`## Breaking Changes`** — Include **only if** the diff suggests breaking changes. Signals: removed public exports, changed function signatures in public modules, renamed/removed API endpoints, removed CLI flags, schema removals, version bumps marked as major in commit messages, or explicit "BREAKING:" markers in commits/body. When present, describe what breaks and the migration path in 1–3 sentences.

**`## Screenshots / Recordings`** — Include **only if** UI/asset files changed. Signals: changes under `components/`, `pages/`, `views/`, `*.tsx`, `*.vue`, `*.svelte`, `*.css`, `*.scss`, `assets/`, `public/`, or image files. If the original body already contains images, preserve them. Otherwise leave a placeholder like `_Attach recording before merge._` so the author remembers.

**`## Pre-Merge Checklist`** — Include **only if** verification leaves items worth tracking (see the next section). Omit when nothing requires human action.

> Reviewers/collaborators are **not** named in the body — assign the PR to them instead (see "Assigning the PR").

### Pre-merge checklist

Render as a GitHub-style task list. Every item is derived from the diff — there are no fixed items.

**Verify before you ask.** The full diff is already in hand from step 3. Any concern the diff itself can answer must be settled during generation, never handed to the author as a chore. Classify each signal into one of two groups:

**Diff-verifiable — check it yourself:**

| Signal in diff                                                   | What to verify in the diff                          |
| ---------------------------------------------------------------- | --------------------------------------------------- |
| New non-trivial logic                                             | Matching test changes accompany it                  |
| Changed public API signatures, exported symbols, or removed CLI flags | All in-repo callers updated                     |
| Changed public API routes or exported handlers                    | Docs / OpenAPI spec updated in the same diff        |

- **Satisfied:** render it checked with one line of evidence — `- [x] Tests added — auth/pkce.test.ts covers the new validation paths` — or drop it if unremarkable. Never emit a diff-verifiable item unchecked.
- **Not satisfied:** that's a finding, not a checkbox. Raise it in the step-7 draft message and only add an unchecked item if the user wants it tracked.

**Environment and process — the real checklist.** Unchecked `- [ ]` boxes are reserved for actions the diff cannot prove:

| Signal in diff / changed files                                   | Add checklist item                                                        |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------- |
| New or modified files under `migrations/`, `db/migrate/`, `schema/`, `*.sql` | Migration run against a production-sized dataset; rollback path verified |
| Config or env var additions                                       | Deployment configs updated for staging and production                     |
| Feature flag references introduced                                 | Feature flag default and rollout plan documented                           |
| Performance-sensitive paths (queries, hot loops, render code)      | Benchmark or load test results captured                                    |
| Changes touching auth, crypto, permissions, secrets handling       | Security review requested                                                  |
| Dependency manifest changes (`package.json`, `Cargo.toml`, etc.)   | Dependency licenses and supply-chain provenance reviewed                   |
| Schema or wire-format changes whose consumers live outside this repo | Backward compatibility verified with downstream consumers              |

Each item should be specific to the PR — paraphrase the rule to mention the actual change. For example, for a new index migration write "Migration tested against a production-sized dataset (drop index is a safe rollback)" rather than the generic wording.

Keep the section short — 1–4 unchecked items is typical; if the rules would produce more, keep the ones most relevant to this PR's risk profile. If no rule produces an item and no verified item is worth reporting, **omit the section entirely**. Never pad it with a generic baseline item like "Backward compatibility verified."

## Worked examples

### Example 1 — feature with breaking change

**Input:** Branch `feature/oauth-pkce`, commits reference `PROJ-456`, diff adds new auth code path with tests in `auth/pkce.test.ts`, modifies `/oauth/authorize` handler, touches mobile SDK files. No UI files, no docs changes. Removes ability to call `/oauth/authorize` without a code challenge.

**Output title:** `feat(auth): PROJ-456 add OAuth2 PKCE flow`

**Output body:**
```markdown

```

Note: no `Screenshots` section because no UI files changed; no migration item because no migration files are touched. The tests item is rendered checked because the diff contains the matching test file. The diff does *not* update API docs for the new required parameter — that gap is raised in the step-7 draft message ("docs not updated for `code_challenge` — gap, or maintained elsewhere?") rather than emitted as an unchecked box. No generic "Backward compatibility verified" item: the compatibility break is intentional and documented in `## Breaking Changes`.

### Example 2 — backend fix, no UI, no breaking changes

**Input:** Body mentions `PROJ-892`. Diff: one new migration file under `migrations/`, one query rewrite in `reports/queries.ts`. No UI files. No public API changes.

**Output title:** `fix(reports): PROJ-892 add index to resolve dashboard timeouts`

**Output body:**
```markdown
## Summary
Dashboard load was timing out for workspaces with >50k events. Adds a
composite index on `events(workspace_id, created_at)` to bring p95 under 300ms.

## What Changed
- New migration `20260510_add_events_workspace_created_idx.sql`
- Reports query rewritten to leverage the new index
- Removed redundant in-memory sort that the index now handles

## How to Test
1. Run migration locally: `pnpm db:migrate`
2. Seed 100k events via `pnpm seed:perf`
3. Hit `/api/reports/overview` and confirm response under 300ms

## Pre-Merge Checklist
- [ ] Migration tested against a production-sized dataset; rollback verified (drop index is safe)
- [ ] Benchmark results captured for the new query
```

Note: no `Breaking Changes` section (none detected), no `Screenshots` section (no UI changes). Both checklist items are environmental — nothing the diff can prove. No "Backward compatibility verified" filler: adding an index changes no contract.

### Example 3 — stacked PR

**Input:** Branch `feature/get-started`, base branch `feature/get-started-be` (not `main`), commits reference `ENG-1005`. Diff adds a new onboarding page driven by a state machine, touches many `*.tsx` components and side-nav. The body already notes it's stacked on #4666 and that #4667 was split off.

**Output title:** `feat(get-started): ENG-1005 add Get Started onboarding page and flow`

**Output body:**
```markdown
## Stack
Frontend half of the get-started onboarding work, split out of the original combined branch.
- **Stacked on #4666** (backend contract) — depends on its `wasFirstStarted` flag; merge #4666 first. GitHub will retarget this PR to `main` once #4666 merges.
- Billing/Shopify read-model changes from the same branch are now independent in #4667.

## Summary
Adds a Get Started onboarding experience that guides merchants from store
connection through launching their first experience, driven by a pure view state machine.

## What Changed
- New Get Started page (hero, progress card, stepper) rendered from a pure `getStartedMachine`
- Onboarding flow: welcome, connect-store, billing plan, and a first-launch celebration dialog
- Script-status checks gain a `quick`/`full` `mode`; all callers updated accordingly
- Moved Get Started to the top of the side nav; added onboarding routes

## How to Test
1. From a fresh org, open `/get-started` and confirm the stepper reflects connect → launch progress
2. Launch a first-ever experience from any surface and confirm the redirect + celebration dialog
3. Launch a subsequent experience and confirm no redirect and no dialog
4. Run frontend unit tests: `moon run frontend:test`

## Screenshots / Recordings
_Attach a recording of the Get Started page before merge._

## Pre-Merge Checklist
- [x] Every `useGetScriptStatus` caller updated to pass the new `mode` argument
- [ ] Confirm the first-launch celebration fires only on the org's first-ever started experience
```

Note: `## Stack` leads because merge order is the reviewer's most urgent context; `## Breaking Changes` is omitted (none). After applying the body, the PR is assigned to the current user with `gh pr edit <ref> --add-assignee @me`; assigning anyone else would require asking first.

## Applying the edit

Pipe the body to `gh pr edit` via stdin using a heredoc. This avoids both shell-quoting issues with multi-line content **and** the zsh `noclobber` failure mode where `cat > $(mktemp)` is rejected because `mktemp` already created the file:

```bash
gh pr edit <ref> --title "<the generated title>" --body-file - <<'EOF'
<the generated body>
EOF
```

**Do not** use the `mktemp` + `cat > "$BODY_FILE"` pattern. Under zsh with `noclobber` set (the default on many setups), the `>` redirect to an existing file fails with `file exists`, the body file stays empty, and `gh pr edit` happily pushes an empty body. The single-tool stdin approach is shorter and immune to this.

**Then verify.** Always run `gh pr view <ref> --json body` after the edit and confirm the body is non-empty and contains `## Summary`. If the body is empty or wrong, the edit silently failed — retry with the stdin form, and tell the user what happened. The cost of a check is one tool call; the cost of falsely reporting success is the user discovering an empty PR on GitHub.

Once verified, confirm success to the user and link to the PR.

## Assigning the PR

Reviewers and collaborators are set as **assignees** via `gh pr edit`, never named in the body.

- **Self — no confirmation needed:** `gh pr edit <ref> --add-assignee @me`. Always safe; do this by default.

If you need to compare a candidate against the logged-in account, resolve it with `gh api user --jq .login`. Prefer `@me` for self-assignment so the login isn't hardcoded. If a `--add-assignee` call fails because the user isn't a collaborator on the repo, surface that to the user rather than silently dropping it.

## Edge cases and judgment calls

- **No ticket found:** Ask the user before producing the title. Don't proceed with a placeholder like `TICKET-???`.
- **Stacked PR / non-default base branch:** Lead with `## Stack` and spell out the merge order. Never rewrite the base branch — just describe the dependency so the reviewer merges in the right order.
- **PR is a draft:** Apply the template normally; draft state doesn't affect the rewrite.
- **Original body has useful content (especially in `How to Test`):** Preserve and integrate it rather than discarding. The author often has context the diff doesn't show.
- **PR is enormous (>5000 line diff):** Sample the diff per file, classify each file's contribution, and aggregate. Mention to the user that the analysis was sampling-based.
- **Multiple ticket IDs match:** Use the one in the branch name if present, otherwise the first one in commits, otherwise ask.
- **User pushed back on a previous draft:** Honor their adjustments. If they say "drop the security review item, this isn't auth code," don't re-add it in a regeneration.
