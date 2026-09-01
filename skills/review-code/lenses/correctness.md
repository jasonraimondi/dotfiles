# Lens: `correctness`

Does the code do what it claims, on every input it will actually see?

## Inputs

Changed files read **in full**. A diff hunk hides the invariant that makes it wrong — this is the one lens where the surrounding code is the evidence.

## Checklist

- **Logic** — wrong operator, inverted condition, off-by-one, unreachable branch
- **Edge cases** — empty, zero, negative, single-element, maximum, concurrent
- **Null and absence** — a value that can be missing, treated as present; a falsy value that is a legitimate result
- **Error handling** — a failure swallowed, logged without recovery, or retried into a worse state
- **Races and ordering** — shared state mutated across await points; assumptions about arrival order
- **Data loss** — an overwrite, truncation, or migration with no path back
- **Broken contracts** — a caller's expectation the change quietly violates: return shape, thrown type, nullability, ordering guarantees
- **Performance that changes behaviour** — N+1 queries, unbounded growth, a missing index on a path that now runs hot

## Output

Per finding: what the code does, what it should do instead, and what breaks in production. A logic error, data-loss path, or broken contract is blocking.

## Rules

Correctness only. Tests belong to `tests`, vulnerabilities to `security`, structure to `architecture` — a finding filed under the wrong lens gets read twice and fixed never.
