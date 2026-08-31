# Lens: `intent`

Single-pass through one lens: did the diff actually deliver what the stated intent claimed? Not correctness, not structure — intent fidelity.

The implementer has rationalizations baked into their session ("I did it this way because…"). A fresh adversarial reader doesn't share those and is more likely to notice what was skipped, hand-waved, or quietly descoped.

## Contract sources

The **contract** is whatever the change promised to do. Take the first of these that yields one:

1. A spec, plan, or ticket path passed as an argument.
2. A ticket reference in the branch name or recent commit messages — fetch it (`gh issue view <n>`, or the tracker's CLI).
3. The commit messages on the branch.
4. A plan or spec doc under `docs/`, `specs/`, or `.scratch/` matching the branch name or feature.
5. A PR's title and body, when the scope is a PR.

**When no contract turns up**, the two callers diverge:

- Invoked directly — say so and stop. Auditing against an invented contract is worse than not auditing.
- Dispatched as an axis by `quick` or `full` — report "no contract available — intent skipped" and return. The other reviewers still stand.

## Workflow

1. Resolve scope (see `../SKILL.md` → *Shared: Resolve scope*).
2. Read the contract in full. Bullet out every promised behavior, named verification step, named interface, listed scope item, acknowledged edge case.
3. Read the diff in full, tests included.
4. **For each intent bullet** — locate the code that delivers it. Not present = gap.
5. **For each diff hunk** — locate the intent bullet that justifies it. Unjustified = scope creep.
6. **For each test** — mentally revert the change being tested. Would the test still pass? Yes = vacuous.
7. Emit findings using the intent output template below, then a verdict.

## Checklist

- **Descoped item** — intent promises X; diff doesn't deliver X.
- **Vacuous test** — passes with the change reverted.
- **Skipped verification** — intent names a verification step ("verified with curl", "tested race condition", "ran the migration in staging") but the diff has no test, log, or evidence.
- **Interface drift** — intent specifies signature, endpoint, schema, or config key; diff implements differently without rationale.
- **Hand-waved error path** — intent acknowledges an error path; diff swallows it, logs without recovery, or doesn't address it.
- **Scope creep** — code the intent doesn't justify (especially: expands public interface, changes unrelated behavior, quietly couples in new deps).
- **Renamed without justification** — names, paths, constants, env vars drifted from the plan with no explanation.

## Output

```
## <PR title (#n), or branch/scope description>

### Stated intent
- bullet 1 (source: PR body L12)
- bullet 2 (source: commit abc1234)

### Critical (descoped items, vacuous tests on the core fix)
1. **[Descoped]** Intent says "validate webhook signature" (PR body L8); diff has no signature check — searched handler.py and middleware.py.

### Suggestions (scope creep, drift, soft gaps)
2. **[Drift]** Plan calls for `fetch(url, opts)`; diff has `fetch(url, opts, retries)` — extra parameter undocumented.

### Nitpicks
3. **[Rename]** Plan refers to `user_id`; diff uses `uid` in three new functions.

### Verdict
ALIGNED | GAPS | DRIFT — one-sentence summary of intent-vs-implementation fit
```

Omit empty sections. Every finding names **both halves**: the intent bullet *and* the missing/divergent code.

## Rules (mode-specific)

- Don't critique the intent itself; audit only whether the diff matches it.
- Don't flag missing features that weren't promised. Don't construct attack scenarios. Don't suggest design improvements.
- Adversarial stance — assume hand-waving until proven otherwise.

Shared rules in `../SKILL.md` apply.
