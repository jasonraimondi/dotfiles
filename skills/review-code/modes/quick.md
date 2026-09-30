# Mode: `quick`

Five reviewers, one round trip, one report. This is the mode a coding agent runs on its own work at the end of an `implement` session — so it answers, it never asks.

## Workflow

1. **Resolve scope** (see `../SKILL.md` → *Shared: Resolve scope*). Quick takes the first thing that resolves and states it; a question here stalls the caller.
2. **Fan out** the five axes below (see `../SKILL.md` → *Shared: Fan-out*).
3. **Assemble** the report (see `../report.md`).

## The five axes

| Axis | Brief | Reads |
|---|---|---|
| Correctness | `lenses/correctness.md` | changed files in full, and the unchanged code the change meets |
| Tests | `lenses/tests.md` | the touched test files in full |
| Intent | `lenses/intent.md` | the diff + the contract |
| Standards & smells | `lenses/standards.md` | the diff + the repo's standards and design records |
| Modularity | `lenses/modularity.md` | `mdlr` output |

For the intent axis, pass the contract if you already have one (`lenses/intent.md` → *Contract sources*).

**A skipped axis is a result.** No `mdlr`, no `gh`, no contract — that axis reports why it skipped, the other four still run, and the report keeps the skip visible.

## Assembling

Four properties make the report work:

- **All five axes appear on the `Reviewers:` line, every run.** Each one ran, skipped with its reason, or failed. An axis left off would read as a clean axis, which is the only way this report can lie.
- **Findings merge into one list, ranked by severity.** Two reviewers landing on the same root cause become one finding that keeps both framings.
- **The engineering rating is set here**, from the reviewers' `Engineering:` lines and the merged findings (see `../report.md` → *Engineering rating*).
- **Citations stand in for the verifier.** There is no verifier in this mode; a complete *Location* and a cited *What is wrong* are what let the caller check a finding in seconds instead of trusting it. A reviewer's claim that arrives without them goes under *Could not verify*.

## Rules

Shared rules in `../SKILL.md` apply.
