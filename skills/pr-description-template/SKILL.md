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
2. **Fetch the data.** Run `gh pr view <ref> --json title,body,headRefName,commits,files,additions,deletions`. This single call returns everything needed.
3. **Fetch the diff for smart todos.** Run `gh pr diff <ref>`. If the diff is large (>2000 lines), truncate sensibly — file headers and a sample of hunks per file is enough to classify changes.
4. **Extract the ticket ID.** Search the PR body and each commit message for a `[A-Z]{2,}-\d+` pattern (e.g., `PROJ-456`, `JIRA-123`). Use the first match. If none is found, note this in the draft and ask the user to supply one (don't fabricate one).
5. **Build the title** following the format below.
6. **Build the description** following the section rules below.
7. **Show the draft to the user.** Display the proposed title and body in a code block. State clearly which sections were omitted and why (e.g., "no breaking changes detected, omitting that section").
8. **Ask for confirmation.** Ask the user something like: "Apply this to PR #123 now? (yes / edit / no)". Wait for an affirmative response.
9. **Apply on confirmation.** Run `gh pr edit <ref> --title "<title>" --body "<body>"`. Use a temp file for the body to avoid shell-quoting issues with multi-line content.

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

Use Markdown. Include sections **only if they have substantive content**. Omit entirely otherwise — don't write "None" or "N/A". The static checklist at the end is the one exception: it always appears, with two fixed items, plus smart additions.

### Section rules

**`## Summary`** — Always include. 1–2 sentences explaining what the PR does and why it matters. No fluff, no restating the title.

**`## What Changed`** — Always include. Bullet list of the meaningful changes (3–6 bullets typical). Group related changes into one bullet rather than listing every file. Skip purely mechanical changes (formatting, import sorting) unless they're the point of the PR.

**`## How to Test`** — Always include. Numbered list of concrete verification steps. Prefer commands and observable outcomes over vague directions. If the original PR body has test instructions, integrate them; don't discard the author's domain knowledge.

**`## Breaking Changes`** — Include **only if** the diff suggests breaking changes. Signals: removed public exports, changed function signatures in public modules, renamed/removed API endpoints, removed CLI flags, schema removals, version bumps marked as major in commit messages, or explicit "BREAKING:" markers in commits/body. When present, describe what breaks and the migration path in 1–3 sentences.

**`## Screenshots / Recordings`** — Include **only if** UI/asset files changed. Signals: changes under `components/`, `pages/`, `views/`, `*.tsx`, `*.vue`, `*.svelte`, `*.css`, `*.scss`, `assets/`, `public/`, or image files. If the original body already contains images, preserve them. Otherwise leave a placeholder like `_Attach recording before merge._` so the author remembers.

**`## Pre-Merge Checklist`** — Always include. See the next section.

### Pre-merge checklist

Render as GitHub-style task list using `- [ ]`. Always include these two static items first:

```
- [ ] Migrations applied
- [ ] Backward compatibility verified
```

Then append smart items derived from the diff. Use these rules:

| Signal in diff / changed files                                  | Add checklist item                                                                 |
| --------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| New files under `migrations/`, `db/migrate/`, `schema/`, `*.sql`| Migration tested against production-sized dataset; rollback path verified          |
| Changed public API routes, OpenAPI specs, or exported handlers  | API docs updated to reflect changes                                                |
| New non-trivial logic without matching test file changes        | Tests added for the new logic paths                                                |
| Changes touching auth, crypto, permissions, secrets handling    | Security review requested                                                          |
| Dependency manifest changes (`package.json`, `Cargo.toml`, etc.)| Verify dependency licenses and supply-chain provenance                             |
| Config or env var additions                                     | Deployment configs updated for staging and production                              |
| Feature flag references introduced                              | Feature flag default and rollout plan documented                                   |
| Performance-sensitive paths (queries, hot loops, render code)   | Benchmark or load test results captured                                            |

Each smart item should be specific to the PR — paraphrase the rule to mention the actual change. For example, if a new `/oauth/authorize` route appears, write "Tests added for new PKCE validation paths" rather than the generic "Tests added for the new logic paths."

Aim for a total checklist of 2–6 items. If smart rules would produce more than 4 additions, keep the most relevant ones for this PR's risk profile and drop the rest.

## Worked examples

### Example 1 — feature with breaking change

**Input:** Branch `feature/oauth-pkce`, commits reference `PROJ-456`, diff adds new auth code path, modifies `/oauth/authorize` handler, touches mobile SDK files. No UI files. Removes ability to call `/oauth/authorize` without a code challenge.

**Output title:** `feat(auth): PROJ-456 add OAuth2 PKCE flow`

**Output body:**
```markdown
## Summary
Adds PKCE support to the OAuth2 authorization flow to harden mobile
clients against authorization code interception.

## What Changed
- New `PKCEChallenge` generator with SHA-256 verifier hashing
- `/oauth/authorize` now validates `code_challenge` and `code_challenge_method`
- Mobile SDK attaches a challenge on every authorization request

## How to Test
1. Run `pnpm test auth/pkce`
2. Trigger login from iOS sim, verify `code_challenge` appears in the auth URL
3. Confirm token exchange fails with a mismatched `code_verifier`

## Breaking Changes
Public clients must now supply `code_challenge`. Existing integrations
without it will receive `400 invalid_request`.

## Pre-Merge Checklist
- [ ] Migrations applied
- [ ] Backward compatibility verified
- [ ] Tests added for new PKCE validation paths
- [ ] API docs updated for the new required parameter
- [ ] Security review requested
```

Note: no `Screenshots` section because no UI files changed.

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
- [ ] Migrations applied
- [ ] Backward compatibility verified
- [ ] Migration tested against production-sized dataset
- [ ] Rollback path verified (drop index is safe)
- [ ] Benchmark results captured for the new query
```

Note: no `Breaking Changes` section (none detected), no `Screenshots` section (no UI changes).

## Applying the edit

Once the user confirms, write the body to a temp file (multi-line content through `--body` directly is fragile in shells). Then:

```bash
BODY_FILE=$(mktemp)
cat > "$BODY_FILE" <<'EOF'
<the generated body>
EOF
gh pr edit <ref> --title "<the generated title>" --body-file "$BODY_FILE"
rm "$BODY_FILE"
```

Confirm success to the user and link to the PR.

## Edge cases and judgment calls

- **No ticket found:** Ask the user before producing the title. Don't proceed with a placeholder like `TICKET-???`.
- **PR is a draft:** Apply the template normally; draft state doesn't affect the rewrite.
- **Original body has useful content (especially in `How to Test`):** Preserve and integrate it rather than discarding. The author often has context the diff doesn't show.
- **PR is enormous (>5000 line diff):** Sample the diff per file, classify each file's contribution, and aggregate. Mention to the user that the analysis was sampling-based.
- **Multiple ticket IDs match:** Use the one in the branch name if present, otherwise the first one in commits, otherwise ask.
- **User pushed back on a previous draft:** Honor their adjustments. If they say "drop the security review item, this isn't auth code," don't re-add it in a regeneration.
