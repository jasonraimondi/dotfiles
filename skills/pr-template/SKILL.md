---
name: pr-template
description: Open a pull request for the current branch, or rewrite an existing PR's title and description, in a conventional-commits + ticket format with a compact, readable body. Use whenever the user wants a PR opened, a PR description formatted, or a PR run through "the template".
---

# PR Template

Opens a pull request for the current branch, or reads an existing one with `gh`, then writes a normalized title and a compact body and applies them. Optimize for density of insight, not minimum word count: explain why the change matters, what changed, and any consequence a reviewer must understand.

## Workflow

1. **Identify the PR.** Use whichever reference the user supplied: number (`gh pr view 123`), URL, branch, or the current branch (`gh pr view` with no arg). A current branch with no PR takes the create path in "Creating the PR", which opens one and hands it to step 2. If ambiguous, ask.
2. **Gather.** `gh pr view <ref> --json title,body,headRefName,baseRefName,commits,files,additions,deletions` and `gh pr diff <ref>`. Read the body first and in full — it is the newest version and the only place the author's intent lives. `baseRefName` tells you whether the PR is stacked. Above ~2000 diff lines, sample it: file headers plus a few hunks per file classify the change. Tell the user in the report that the analysis was sampled.
3. **Triage the body against the diff.** See "Triage the body". On the create path the body is empty and the session that did the work holds the intent: its reasons, test runs, and screenshots are the claims, and the same verdicts apply.
4. **Read the ticket and `GLOSSARY.md`.** Use `{argument}` for the ticket if given; otherwise search the body, the branch name, and every commit message for `[A-Z]{2,}-\d+` (e.g. `PROJ-456`). Read each ticket you find and treat its description as a claim too — the code is what shipped. Read `GLOSSARY.md` if the repo has one (root, or the nearest ancestor directory of the changed files); its terms govern the wording you write.
5. **Build the title and the body.** The title follows "Title format" below. The body follows `references/format.md`: read it now, in full. It holds the sections, shape sketches, blockers, and two worked examples.
6. **Compress.** Apply "Length" in `references/format.md`. Delete low-value detail instead of packing it into longer sentences.
7. **Unslop.** Use Skill(unslop). Apply its process and every pattern check to the title and body, but skip "Adding soul": a PR body states facts without opinion or first person. Preserve verified technical meaning, conventional title syntax, Markdown headings, the `**Door:**`, `**Blast radius:**`, and `**Before merge:**` labels, literal code, and task-list syntax. This step is complete when the self-audit finds no remaining tell.
8. **Apply.** Pipe the body through stdin. See "Applying the edit". Apply as soon as it is written. `gh pr edit` is re-runnable, so a rewrite the user dislikes costs one more run.
9. **Verify.** Run `gh pr view <ref> --json title,body` and confirm the body is non-empty and opens with `## Why` or `## Stack`. A mismatch means the apply failed. Retry and tell the user. Report success only after this check passes.
10. **Assign.** `gh pr edit <ref> --add-assignee @me`, plus any login the user named in their instruction.
11. **Report.** Print the PR URL, then the applied title and body in a code block, then only what needs the user's judgment: every contradicted claim with its evidence, every claim still unverified, and every gap from the diff audit. When the diff spans unrelated top-level areas, add one line suggesting the PR be split.

On a stack, steps 2–11 run once per PR the create path collected, and the report lists every PR.

## Creating the PR

Runs when the current branch has no PR. Each check stops the skill with its finding, and nothing opens.

1. **Clean tree.** `git status --porcelain` prints nothing. Dirty files are listed for the user to commit; commits are theirs alone.
2. **Single or stack.** `gh stack view --json` succeeding and listing the current branch means a stack. Anything else is a single branch.
3. **Single branch.** Run the touched tests. Then `git push -u origin HEAD` and `gh pr create --draft --base <default branch> --title "<branch name>" --body ""`, with the default branch from `gh repo view --json defaultBranchRef`. The PR it prints is the one step 2 of the workflow gathers.
4. **Stack.** `gh stack submit --auto`. Collect every layer whose PR body does not open with `## Stack` or `## Why`, from `gh stack view --json`. For each, `gh stack checkout <branch>` and run its touched tests before its pass through steps 2–11. A failing layer stops the loop there, and the layers already written stay. Finish on the branch the skill started from.

**Draft or ready.** Draft by default. "Ready" in the user's instruction drops `--draft` and adds `--open` to `gh stack submit`.

**Touched tests.** The test files in the diff against the base, plus the test file beside each changed source file, run with the repo's test runner. A failure stops with the output. A pass is the A-tier result that `## How to verify` records; a before-state is stated only when the session recorded a red run.

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
- **Breaking change or migration?** Append `!` before the colon: `feat(auth)!: PROJ-456 add OAuth2 PKCE flow`. Any PR whose diff adds or changes a migration (the migration signal in the Blockers table of `references/format.md`) gets the `!`, even when nothing else in it breaks. The title becomes the squash-merge commit message, so the marker belongs there as well as in the body.

## Diff audit

You hold the full diff, so settle these yourself during generation. Findings go in the report, never in the body.

| Signal in the diff                                                | Verify in the diff                  |
| ------------------------------------------------------------------ | ----------------------------------- |
| New non-trivial logic                                              | Matching test changes accompany it  |
| Changed public signatures, exported symbols, or removed CLI flags  | All in-repo callers updated         |
| Changed public routes or exported handlers                         | Docs / OpenAPI updated in this diff |

A gap is a question for the chat: "new logic in `auth/pkce.ts` ships with no test changes — gap, or covered elsewhere?" It reaches the body as a `**Before merge:**` item only when the user asks to track it.

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
- **Several ticket IDs match:** prefer the one in the branch name, then the first in commits.
- **User wants a change after the apply:** honor the adjustment and re-apply. A dropped item stays dropped through later rewrites.
