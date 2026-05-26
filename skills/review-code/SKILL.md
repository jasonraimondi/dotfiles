---
name: review-code
description: "Code-review skill with mode routing. Default lens is `standard` (alias `quick`) — correctness, security, quality in one pass with a verdict. Other modes: `security` (OWASP, high-confidence only), `architecture` (module depth, coupling, boundaries), `merge-risk` (shippability + reversibility), `intent` (alias `adversarial`) — does the diff deliver what was promised, `multi` (alias `full`) — six parallel reviewers plus a verifier. Invoke as /review-code [<mode>] [<scope>]. Use for any code-review or PR-audit task."
argument-hint: "[standard|quick|security|architecture|merge-risk|intent|adversarial|multi|full] [<scope>]"
license: LICENSE
---

# Code Review

One skill, six lenses. Each mode lives in its own file under `modes/`; load it on dispatch.

| Mode | Question it answers | File |
|---|---|---|
| `standard` *(default, alias `quick`)* | correctness, security, quality — single pass with a verdict | `modes/standard.md` |
| `security` | exploitable OWASP-style vulnerabilities (high-confidence only) | `modes/security.md` |
| `architecture` | module depth, coupling, abstraction boundaries, layering | `modes/architecture.md` |
| `merge-risk` | shippability and reversibility — SHIP / SHIP WITH MITIGATIONS / HOLD / DO NOT MERGE | `modes/merge-risk.md` |
| `intent` *(alias `adversarial`)* | did the diff deliver what the stated intent promised | `modes/intent.md` |
| `multi` *(alias `full`)* | six reviewers in parallel through a verifier — most thorough | `modes/multi.md` |

## Dispatch

`/review-code [<mode>] [<scope>]`. **Mode defaults to `standard`** when omitted.

If the user's phrasing implies a different mode, pick it:

- "security review" / "find vulnerabilities" → `security`
- "architecture review" → `architecture`
- "merge safety" / "is this safe to merge" → `merge-risk`
- "audit against PR description" / "intent fidelity" / "adversarial review" → `intent`
- "thorough review" / "deep review" / "multi-agent" / "full review" → `multi`

**Aliases**:
- `quick` → `standard` (single-pass default; load `modes/standard.md`)
- `adversarial` → `intent` (gap-audit against stated intent; load `modes/intent.md`)
- `full` → `multi` (thorough parallel review; load `modes/multi.md`)

If ambiguous, ask. Then **load `modes/<canonical-mode>.md` and follow it.**

Scope accepts: PR number, PR URL, branch reference, "this branch" / "my changes", file paths, "these changes". Resolve once via the shared section below.

---

## Shared: Resolve scope

All modes start here.

1. **PR** — `gh pr view <n> --json title,body,baseRefName,headRefName,files,commits` for metadata; `gh pr diff <n>` for the diff.
2. **Branch** — "this branch" / "my changes" with no PR: detect the default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, or `git symbolic-ref refs/remotes/origin/HEAD`); diff against the merge-base: `git diff $(git merge-base HEAD <base>)...HEAD`.
3. **Working tree** — named files or "these changes": `git diff` / `git diff --staged`, or the named files directly.
4. **Unclear** — no PR and a clean working tree: `gh pr list` and ask. Otherwise ask which scope.

Resolve once. In `multi` mode, pass the same resolved scope to every reviewer so they all review the same code.

## Shared: Standard output template

Used by `standard` and `architecture`. `intent` has its own variant; `security`, `merge-risk`, and `multi` define their own.

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

Omit empty sections. No filler praise.

## Shared: Common rules

Apply to every mode unless the mode overrides:

- **Never approve or submit a review on behalf of the user.**
- **Never run** `gh pr review`, `gh pr comment`, `gh pr merge`, `gh pr approve`.
- Cite `file:line` for every code-level claim.
- Flag uncertainty rather than guessing.
- Stay scoped to the diff. Don't review unchanged code unless directly affected.
