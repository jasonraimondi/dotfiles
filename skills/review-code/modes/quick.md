# Mode: `quick`

Five reviewers, one round trip, a list of what to fix before committing. This is the mode a coding agent runs on its own work at the end of an `implement` session — so it answers, it never asks.

## Workflow

1. **Resolve scope** (see `../SKILL.md` → *Shared: Resolve scope*). Quick takes the first thing that resolves and states it; a question here stalls the caller.
2. **Fan out** the five axes below (see `../SKILL.md` → *Shared: Fan-out*), then assemble the report.

## The five axes

| Axis | Brief | Reads |
|---|---|---|
| Correctness | `lenses/correctness.md` | changed files in full |
| Tests | `lenses/tests.md` | the touched test files in full |
| Intent | `lenses/intent.md` | the diff + the contract |
| Standards & smells | `lenses/standards.md` | the diff |
| Modularity | `lenses/modularity.md` | `mdlr` output |

Each agent also gets the finding format from *Report shape* below and a 400-word cap. For the intent axis, pass the contract if you already have one (`lenses/intent.md` → *Contract sources*).

**A skipped axis is a result.** No `mdlr`, no `gh`, no contract — that axis reports why it skipped, the other four still run, and the report keeps the skip visible.

## Report shape

```
## Quick review — <resolved scope>

### Correctness
1. [BLOCKING] src/auth.ts:88 — `if (!user)` never fires: `findUser` returns `{}` on a miss, not null.
   > `const user = await findUser(id)`

### Tests
2. [BLOCKING] src/auth.spec.ts:112 — passes with the fix reverted; it asserts the call happened, not the result.
   > `expect(findUser).toHaveBeenCalled()`

### Intent
No findings.

### Standards & smells
### Modularity
mdlr not installed — skipped.

### Fix before commit
- src/auth.ts:88 — null check never fires (Correctness)
- src/auth.spec.ts:112 — test passes with the fix reverted (Tests)
```

Four properties make the report work:

- **All five axis headings appear, every run**, plus *Fix before commit*. An axis with nothing to say says `No findings.`; one that skipped says why; one whose agent died says that. An absent section would read as a clean axis, which is the only way this report can lie.
- **Every finding quotes its evidence** — a `file:line` and the verbatim diff line under it. There is no verifier in this mode; the quote is what lets the caller check a finding in seconds instead of trusting it.
- **`[BLOCKING]` is the only severity.** Tag a finding when the code should not be committed as-is: a logic error, a data-loss path, a broken contract, a test that would not catch a regression on a risky path, a descoped promise, a `critical` mdlr bucket.
- **Axes stay separate.** *Fix before commit* is a filter — it re-lists the `[BLOCKING]` findings and names the axis each came from, or reads `None`. The axis sections above it keep every finding, in their own order. Merging or re-ranking across axes is what lets a clean axis mask a failing one.

An empty *Fix before commit* is the verdict; skip the summary line.

## Rules

Shared rules in `../SKILL.md` apply.
