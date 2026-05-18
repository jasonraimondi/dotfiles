---
name: review-architecture
description: Single-pass architecture and design review of a pull request or local changes. Evaluates module depth, coupling, abstraction boundaries, layering, testability at the seams, naming, and dead weight. Use when asked for an "architecture review", or to "review the structure", check coupling or module boundaries, or as the design reviewer in a multi-agent review.
---

# Architecture & Design Review

Single-pass review through one lens: did this change make the codebase's structure better or worse? Not correctness, not security — structure and design quality.

A **deep module** (Ousterhout, *A Philosophy of Software Design*) hides a large implementation behind a small interface. Shallow modules, leaky boundaries, and tight coupling are the friction this review surfaces.

## Input — resolve the scope first

Review a pull request or local changes:

1. **PR** — PR number or URL: `gh pr view <n> --json title,body,baseRefName,headRefName,files` and `gh pr diff <n>`.
2. **Branch** — "this branch" / "my changes" with no PR: diff against the merge-base with the default branch — `git diff $(git merge-base HEAD <base>)...HEAD`.
3. **Working tree** — named files or "these changes": `git diff` (unstaged) and `git diff --staged`, or read the named files directly.
4. **Unclear** — no PR given and a clean working tree: run `gh pr list` and ask which PR. Otherwise ask which scope is meant.

## Workflow

1. **Resolve scope** and get the diff (see Input).
2. **Read changed files in full, plus their callers** — architecture lives in the seams; a diff alone hides coupling.
3. **Analyze** each change against the checklist; skip dimensions that don't apply.
4. **Emit** findings grouped by severity, then a verdict.

## Checklist

- **Module depth** — new modules or functions whose interface is nearly as complex as their implementation; pass-through wrappers that add a name but no abstraction.
- **Coupling** — new dependencies between modules that should not know about each other; a change that ripples across many files because one concept is spread thin.
- **Abstraction boundaries** — interfaces leaking implementation detail; callers forced to know internals; types crossing a boundary they shouldn't.
- **Layering** — direction-of-dependency violations (domain importing infra, UI reaching into persistence).
- **Responsibility placement** — logic bolted onto a convenient caller instead of the module that owns the concept.
- **Testability at the seam** — can the new behavior be tested at the module boundary, or only by reaching inside? Pure functions extracted for testing while the real bug surface — how they're wired — stays untested.
- **Speculative structure** — abstractions, parameters, or extension points with a single caller and no concrete second use.
- **Naming & clarity** — names express intent; control flow is followable without tracing every branch.
- **Dead weight** — code, exports, or parameters the change leaves unused.

## Output

```
## <PR title (#n), or branch/scope description>

### Critical
1. file:line — finding

### Suggestions
2. file:line — finding

### Nitpicks
3. file:line — finding

### Verdict
APPROVE | REQUEST_CHANGES | COMMENT — one-sentence rationale
```

Omit empty sections. Each finding names the structural problem *and* the cheaper shape — not just "this is coupled".

## Rules

- Stay scoped to the change. Pre-existing architecture problems are out of scope unless the change makes them worse.
- Never approve or submit a review on behalf of the user without explicit confirmation.
- Propose the smaller-interface alternative concretely; flag uncertainty rather than guessing.
