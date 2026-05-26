---
name: review-adversarial
description: "Adversarial gap audit: read the stated intent (PR description, commit messages, plan or task doc) and audit the diff against it. Surfaces items quietly descoped, vacuous tests that pass with the change reverted, verification steps that weren't run, and interface drift. Use when asked to 'audit against the PR description', 'find gaps in the diff', 'intent vs. implementation', 'check what was hand-waved', or as the adversarial reviewer in a multi-agent review."
---

# Adversarial Gap Audit

Single-pass review through one lens: did the diff actually deliver what the stated intent claimed? Not correctness, not structure — intent fidelity.

The implementer has rationalizations baked into their session ("I did it this way because…"). A fresh adversarial reader doesn't share those and is more likely to notice that something was skipped, hand-waved, or quietly descoped.

## Input — resolve scope and stated intent

The "stated intent" is the contract the diff is meant to satisfy. Where it lives depends on the scope:

1. **PR** — `gh pr view <n> --json title,body,baseRefName,headRefName,files,commits` for the description and commits, `gh pr diff <n>` for the diff. Stated intent = PR title + body + commit messages.
2. **Branch** — `git log <base>..HEAD` for commits, `git diff $(git merge-base HEAD <base>)...HEAD` for the diff. Stated intent = commit messages plus any plan or task doc passed in scope.
3. **Working tree** — `git diff` / `git diff --staged`, plus any plan or task doc passed in scope.

If no stated intent is available (working tree with no plan doc and uninformative commit messages), say so and stop — there's nothing to audit against. Don't invent a contract.

## Workflow

1. **Read the stated intent in full.** Bullet out every promised behavior, named verification step, named interface, listed scope item, and acknowledged edge case.
2. **Read the diff in full**, tests included.
3. **For each intent bullet** — locate the code that delivers it. If not present, that's a gap.
4. **For each diff hunk** — locate the intent bullet that justifies it. If unjustified, that's scope creep.
5. **For each test** — mentally revert the change being tested. Would the test still pass? If yes, the test is vacuous for the stated bug.
6. **Emit** findings grouped by severity, then a verdict.

## Checklist

- **Descoped item** — the intent promises behavior X; the diff doesn't deliver X.
- **Vacuous test** — the test passes with the change reverted. The test exercises something other than the new code's contract.
- **Skipped verification** — the intent names a verification step ("verified with curl", "tested race condition", "ran the migration in staging") but the diff carries no test, log, or evidence the step was actually run.
- **Interface drift** — the intent specifies a signature, endpoint, schema, or config key that the diff implements differently, without rationale.
- **Hand-waved error path** — the intent acknowledges an error path ("handle the case where X fails") but the diff swallows it, logs without recovery, or doesn't address it.
- **Scope creep** — code the intent doesn't justify. Incidental cleanup is fine; flag when it expands public interface, changes unrelated behavior, or quietly couples in new dependencies.
- **Renamed without justification** — names, paths, constants, or env vars that drifted from the plan with no explanation.

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

Omit empty sections. Every finding names **both halves**: the intent bullet *and* the missing/divergent code. A finding with only one half is unverifiable — drop it.

## Rules

- Don't critique the intent itself; audit only whether the diff matches it. ("The PR description is vague" is out of scope; "the diff doesn't deliver what the description names" is in scope.)
- Don't flag missing features that weren't promised. Don't construct attack scenarios — that's not this role.
- Don't suggest design or structural improvements. Stay scoped to intent fidelity.
- Adversarial stance — assume hand-waving until proven otherwise. But each finding still needs both halves: the intent claim and the divergent code.
- If no stated intent is available, say so and stop. Don't audit against an invented contract.
- Never approve or submit a review on behalf of the user.
