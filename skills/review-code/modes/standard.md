# Mode: `standard`

Single-pass review. One read, one report. **Default mode** when none is given.

## Workflow

1. Resolve scope (see SKILL.md → *Shared: Resolve scope*).
2. Read changed files in full — surrounding code determines correctness.
3. Walk each change against the checklist; skip dimensions that don't apply.
4. Emit findings using the standard output template (see SKILL.md → *Shared: Standard output template*), then a verdict.

## Checklist

- **Correctness** — logic errors, edge cases, off-by-ones, null/undefined paths
- **Security** — injection, auth gaps, secret exposure, unsafe deserialization (for deeper coverage, switch to `security` mode)
- **Breaking changes** — API contracts, removed exports, schema migrations
- **Tests** — new behavior has tests; existing tests aren't weakened
- **Naming & clarity** — variables, functions, types express intent
- **Performance** — unnecessary allocations, N+1 queries, missing indexes

Shared rules in SKILL.md apply.
