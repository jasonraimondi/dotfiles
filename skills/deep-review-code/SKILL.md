---
name: deep-review-code
description: "Reviews a diff. `quick` (default) fans out five parallel reviewers — correctness, tests, intent, standards & smells, modularity — and ends in a verdict with findings ranked by severity; use it for \"review this branch / these changes\" and after implementing work, before committing. `full` is eight reviewers plus a verifier, run only when named, for a final PR review. Single lenses: `security`, `architecture`, `merge-risk`, `intent`. Invoke as /review-code [<mode>] [<scope>]."
argument-hint: "[quick|full|security|architecture|merge-risk|intent] [<scope>]"
disable-model-invocation: true
---

# Code Review

A **mode** owns how the review runs. A **lens** owns what to look for. `report.md` owns what the report looks like. Modes compose lenses; four lenses are also worth running alone.

| Mode | Question it answers | File |
|---|---|---|
| `quick` *(default)* | what must I fix before I commit this | `modes/quick.md` |
| `full` *(alias `multi`)* | is this pull request ready, verified | `modes/full.md` |

| Lens | Question it answers | File |
|---|---|---|
| `security` | exploitable OWASP-style vulnerabilities, high-confidence only | `lenses/security.md` |
| `architecture` | module depth, coupling, abstraction boundaries, layering | `lenses/architecture.md` |
| `merge-risk` | shippability and reversibility — SHIP / SHIP WITH MITIGATIONS / HOLD / DO NOT MERGE | `lenses/merge-risk.md` |
| `intent` *(alias `adversarial`)* | did the diff deliver what the contract promised | `lenses/intent.md` |

The other four lenses — `correctness`, `tests`, `standards`, `modularity` — run inside the modes.

## Dispatch

`/review-code [<mode>] [<scope>]`. **No mode means `quick`.**

Match the user's phrasing to a mode or lens:

- "review this branch" / "review my changes" / finishing an implementation → `quick`
- "full review" / "multi-agent" / final review of a PR → `full`
- "security review" / "find vulnerabilities" → `security`
- "architecture review" → `architecture`
- "is this safe to merge" → `merge-risk`
- "audit against the PR description" / "adversarial review" → `intent`

Then **load the file and follow it**. If the phrasing is genuinely ambiguous, run `quick` and say so — it's the cheap answer, and it names what it skipped.

## Shared: Resolve scope

Resolve once, and pass the resolution verbatim to every agent a mode dispatches, so they all review the same code at the same ref.

1. **Explicit argument** — a PR number or URL (see *Pull requests* below); a branch or commit ref (`git diff $(git merge-base HEAD <ref>)...HEAD`); or file paths, taken as given.
2. **No argument, dirty working tree** — `git diff`, `git diff --staged`, and the untracked files from `git ls-files --others --exclude-standard`. A new file appears in no diff, and it's the code most worth reviewing.
3. **No argument, clean tree** — the branch against its base: detect the default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, else `git symbolic-ref refs/remotes/origin/HEAD`), then `git diff $(git merge-base HEAD <base>)...HEAD`.

**Pull requests** are read at their head, from a ref, with the working tree left as it is — the checkout holds some other branch, and a file opened from disk is the wrong code.

- Metadata: `gh pr view <n> --json title,body,baseRefName,headRefName,headRefOid,files,commits,comments,reviews,mergeStateStatus,statusCheckRollup`. The comments and reviews say what has already been raised.
- Refs: `git fetch origin <base> +pull/<n>/head:refs/review/pr-<n>`.
- Diff: `git diff origin/<base>...refs/review/pr-<n>`.
- Files: `git show refs/review/pr-<n>:<path>`.

The resolution becomes the report's `Scope:` line: the diff command, the head SHA, the commit and file counts, how the code was read, and what was and was not run. `full` and the single lenses may ask when the scope is genuinely ambiguous.

## Shared: Fan-out

For the modes that dispatch reviewers:

- **One message, every agent.** Separate messages run sequentially and throw away the parallelism that is the whole point.
- **Each agent reads its own brief.** Hand it the lens file's path and `report.md`'s, relative to this skill's base directory, rather than pasting the contents — the brief stays out of the dispatcher's context.
- **The same resolved scope, verbatim, for everyone** — reviewers and verifier alike, so every finding refers to the same code at the same ref.
- **The dispatcher waits while reviewers run.** Its spot check is `git diff --stat` or one file with offset and limit; the reviewers read the diff.
- **Every reviewer brief caps its return**: findings in the anatomy, *Could not verify* prose only where it changes the verdict, ≤600 words.
- **An agent that fails or returns nothing gets named on the report's `Reviewers:` line.** A missing reviewer reads as a clean axis, which is the one way this can lie.
- **Without the Agent tool** — you are already inside a subagent — work the briefs one after another in this context and put `Fan-out unavailable — reviewers run sequentially.` on the `Reviewers:` line.

## Shared: Report shape

`report.md` holds the report shape, the finding anatomy, and the severity scale. Every mode reports in it, and so does a lens invoked directly, unless the lens defines its own template. In `full` mode the verifier reads it; the dispatcher passes its path.

## Shared: Common rules

Every mode and lens, unless it overrides:

- **Report only.** Leave the edits, the commit, and the push to the caller — a review that changes the code makes its own findings unfalsifiable.
- **The user submits reviews, not you.** Never run `gh pr review`, `gh pr comment`, `gh pr merge`, or `gh pr approve`.
- Cite `file:line` for every code-level claim, and name the symbol or quote the expression the claim rests on.
- Say what's uncertain rather than guessing past it: inside the finding, or under *Could not verify*.
- Stay inside the diff. Unchanged code is in scope only where the change makes it wrong.
