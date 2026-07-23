---
name: best-practices-comments
description: Audit code comments — flag and propose removal of low-value comments, and surface refactoring opportunities that would make a comment unnecessary. Use when the user asks to "review comments", "audit comments", "clean up comments", or check comment quality.
---

## Scope

Determine what to audit based on how the skill was invoked:

1. **PR-scoped** — user supplied a PR number, URL, or said "this PR" / "the PR on this branch":
   - Resolve the PR with `gh pr view <ref> --json number,headRefName,baseRefName,url`.
   - Get the diff with `gh pr diff <ref>` (or `gh pr diff` for the current branch's PR).
   - Audit **only comment lines that were added** in that diff (lines beginning with `+` that are comments in their language). Ignore context lines, removed lines, and pre-existing comments — even if they look bad. They are out of scope.
2. **Branch-scoped** — user says "this branch", "my changes", or similar without a PR:
   - Use `git diff <base>...HEAD` where `<base>` is the merge-base with `main` (or the repo's default branch). Audit only added comment lines.
3. **Working-tree-scoped** — user provides specific files or says "this file" / "these changes":
   - Audit comments in the named files, or `git diff` for unstaged/staged changes.
4. **Unscoped** — if scope is unclear, ask the user which of the above they want before auditing.

A noisy comment on line 200 of a file is not your concern if only line 42 was touched in the PR.

## Rules — what to flag

Treat comments as a necessary evil. Flag any comment that falls into these categories:

- **Journal comments** — running logs of decisions made over the PR's lifetime ("changed this from X to Y because…", "removed old impl", dates, TODOs from the author to themselves).
- **Noise comments** — restate what the code obviously does (`// increment i`, `# return the user`).
- **Nonlocal information** — point to gitignored planning docs, internal tickets, Slack threads, or context a future reader cannot see from the code alone. (A bare ticket ID with no explanation also counts.)
- **Redundant comments** — repeat what the function or variable name already says.
- **Mumbling and attributions** — half-thoughts, "I tried X then Y", "per Alice's suggestion", authorship marks, AI tool tags.
- **Stale comments** — describe behavior the code no longer does.

Keep comments that earn their place: intent that the code cannot express, warnings of non-obvious consequence, clarification of genuinely obscure decisions (with the *why*), or legally required notices (licenses, SPDX, attribution required by upstream).

## Refactor opportunities

For each surviving comment, ask: could the code be made self-explanatory instead? Possible refactors:

- Rename a variable, function, or parameter so the comment becomes redundant.
- Extract a function whose name captures what the comment was explaining.
- Introduce an explaining variable for a magic value or condition.
- Replace a magic number with a named constant.

If a refactor would let you delete the comment, **propose it**.

## Output — propose, do not apply

Emit a single grouped report. Account for every added comment line in scope: each is either flagged here or silently kept. Do **not** edit files in this step. For each finding include:

- `file:line` of the added comment.
- The comment text (verbatim, trimmed).
- Category from the list above.
- Recommendation: `DELETE`, `REFACTOR + DELETE`, or `KEEP` (only include KEEP entries if explaining a non-obvious save).
- For `REFACTOR + DELETE`: a concrete one-line description of the refactor (e.g., "rename `d` → `daysUntilExpiry`, then delete comment").

Group findings by file. End the report with a short summary count (e.g., `7 DELETE, 2 REFACTOR + DELETE, 1 KEEP`).

Then ask the user which to apply. Accept any of:

- "all" / "yes" — apply every DELETE and REFACTOR + DELETE.
- "deletes only" — apply DELETEs, skip refactors.
- A list of indices or `file:line` references — apply only those.
- "none" / "skip" — make no changes.

## Applying changes — only after confirmation

Once the user confirms:

1. Apply DELETEs with `Edit`. Match the exact comment text including surrounding whitespace so the edit is unambiguous.
2. For REFACTOR + DELETE: perform the rename/extract/etc. first, verify nothing else needs updating (use `grep` for renamed identifiers across the scope), then delete the now-redundant comment.
3. After all edits, re-run the diff (`gh pr diff` or `git diff`) and confirm only the intended comment lines and refactor lines changed. Report what was applied.

If any change would touch code outside the audit scope (e.g., a rename that ripples into untouched files), surface that before applying and ask whether to proceed.
