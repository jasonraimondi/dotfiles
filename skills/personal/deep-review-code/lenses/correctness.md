# Lens: `correctness`

Does the code do what it claims, on every input it will actually see?

## Inputs

Changed files read **in full**. A diff hunk hides the invariant that makes it wrong — this is the one lens where the surrounding code is the evidence.

Then follow each new behaviour into the unchanged code it meets: its callers, the other writers of the same state, the jobs and handlers that run later. The bug a change introduces often sits in a file the change never touched.

## Checklist

- **Logic** — wrong operator, inverted condition, off-by-one, unreachable branch
- **Edge cases** — empty, zero, negative, single-element, maximum, concurrent
- **Null and absence** — a value that can be missing, treated as present; a falsy value that is a legitimate result
- **Error handling** — a failure swallowed, logged without recovery, or retried into a worse state
- **Races and ordering** — shared state mutated across await points; assumptions about arrival order
- **Data loss** — an overwrite, truncation, or migration with no path back
- **Leftover state** — something the change creates (a scheduled job, a booking, a cache entry, a row) that outlives what it was created for. Walk the lifecycle — create, cancel, create again — and ask what the first one's leftovers do to the second
- **Broken contracts** — a caller's expectation the change quietly violates: return shape, thrown type, nullability, ordering guarantees
- **Performance that changes behaviour** — N+1 queries, unbounded growth, a missing index on a path that now runs hot

## Output

Per finding: what the code does, what it should do instead, and the scenario that breaks in production. A logic error, data-loss path, or broken contract is blocking.

## Rules

Correctness only. Tests belong to `tests`, vulnerabilities to `security`, structure to `architecture` — a finding filed under the wrong lens gets read twice and fixed never.
