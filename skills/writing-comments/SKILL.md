---
name: writing-comments
description: Use when about to write a comment, when judging whether one earns its place, or when asked to review, audit, or clean up comments.
---

# Writing comments

Comments are a necessary evil. **Default to none.** The code is the document; a comment is what you add when the code cannot be made to say it.

## The ladder

A comment you are about to write is a signal that the code is unclear. Climb the ladder in order and stop at the first rung that removes the need:

1. **Rename** — a variable, function, or parameter whose name says what the comment says.
2. **Extract** — a function whose name captures the block the comment was introducing.
3. **Explaining variable** — bind the condition or expression to a named value.
4. **Named constant** — replace the magic number or string.

```js
// only send if the user has not been emailed in the last 24h
if (Date.now() - u.lastAt > 86_400_000) {
```

```js
const emailCooledDown = Date.now() - user.lastEmailedAt > EMAIL_COOLDOWN_MS;
if (emailCooledDown) {
```

## What earns a comment

Past the ladder, only the *why* survives — the code already shows the *what*. Write one when it carries:

- **Intent** the code cannot express — the goal behind an implementation that otherwise looks arbitrary.
- **A non-obvious consequence** — what breaks if the order changes, why the lock is held this wide.
- **The road not taken** — why the obvious approach fails here.
- **An external constraint** — a workaround for an upstream bug, a spec requirement, a wire-format quirk.
- **A legal notice** — license, SPDX, attribution required by upstream.

```js
// Retry before refreshing auth: a refresh invalidates the token this
// request already signed with, so the retry would 401.
```

## How to write it

- **Stand alone.** Write for a reader who has only the code in front of them. Put the reason in the comment itself — ticket IDs, Slack threads, PR numbers, planning docs, and ADR or design-doc numbers all rot silently, because nothing enforces the reference when the target is renumbered, superseded, or deleted.
- **Describe the code as it is now**, in the present tense. Git holds the change.
- **One or two lines.** Longer means the design needs a doc, or the code needs another turn on the ladder.
- **Put it beside what it explains** — directly above the line or block.

Guardrails, since each of these reads as a comment but carries nothing a reader can use: restatements of the code (`// increment i`) or of a name already on the function; journals (change logs, dates, "changed from X to Y", "removed old impl", TODO-to-self); attributions ("per Alice", authorship marks, AI tool tags); commented-out code.

## API docs are a separate contract

A docstring on a public function — JSDoc, Python docstring, Go doc comment — documents a contract for callers who never read the body: parameters, return, raised errors, units, ownership. The ladder does not apply, and a good name does not replace a documented contract. Follow the file's existing convention. Private internals get none by default.

## Auditing comments already written

When the task is to review, audit, or clean up comments rather than write them:

1. **Scope it.** A PR (`gh pr diff <ref>`), a branch (`git diff <merge-base>...HEAD`), or named files. Judge only comment lines **added** in that diff — a noisy comment on line 200 is out of scope if the diff touched line 42. Ask which scope applies if it is unclear.
2. **Judge each added comment** against the rules above. Account for every one: it is either reported or silently kept.
3. **Report, do not apply.** Group by file. Per finding give `file:line`, the comment verbatim, and one of `DELETE`, `REFACTOR + DELETE` (with the one-line refactor, e.g. "rename `d` → `daysUntilExpiry`"), or `KEEP` (only when the save is non-obvious). End with a count. Then ask which to apply.
4. **Apply what the user picks.** Do the refactor first, `grep` the renamed identifier across the scope, then delete the now-redundant comment. Re-run the diff and confirm only the intended lines changed. If a rename ripples outside the scope, say so before applying.
