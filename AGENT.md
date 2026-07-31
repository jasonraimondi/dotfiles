## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Comments

**Comments are a necessary evil. Default to none.**

- Prefer self-documenting code — a better name, an extraction, an explaining variable, a named constant — over a comment.
- If a comment survives, it explains **why** — intent, a non-obvious consequence, the reason for an obscure choice. The code already shows *what*.
- Make it stand alone for a reader who sees only the code: no pointers to tickets, Slack, PRs, or planning docs.
- No journaling: no change logs, dates, TODO-to-self, "per Alice", authorship marks, or AI tags.

## Git

- NEVER WRITE coauthored by agent, or written by agent

### GitHub
- **IMPORTANT**: When creating a PR always assign to me
- **IMPORTANT**: Use the Skill(gh-stack) whenever creating, rebasing, or reordering 2+ dependent branches/PRs in one task. Avoid rebasing stacked branches manually

## Info
- When reporting information to me be extremely concise and sacrifice grammar for concision
