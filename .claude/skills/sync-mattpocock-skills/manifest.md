# Manifest

Last-synced upstream commit: `49dd158` (post-v1.3.1, 2026-10-09)

Paths are relative to this repo (local) and to the upstream repo root (upstream).

## Tracked

| Local | Upstream | Kept divergence |
|---|---|---|
| `pending/claude-handoff` | `skills/in-progress/claude-handoff` | parked in `pending/` (not installed) |
| `vendor/grill-me` | `skills/productivity/grill-me` | none |
| `vendor/grill-with-docs` | `skills/engineering/grill-with-docs` | none |
| `vendor-auto/handoff` | `skills/productivity/handoff` | none |
| `vendor/teach` | `skills/productivity/teach` | none |
| `vendor/to-questionnaire` | `skills/productivity/to-questionnaire` | none |
| `vendor/wait-what` | `skills/productivity/wait-what` | none |
| `vendor/wizard` | `skills/engineering/wizard` | none |
| `vendor-auto/codebase-design` | `skills/engineering/codebase-design` | none |
| `vendor-auto/diagnosing-bugs` | `skills/engineering/diagnosing-bugs` | Phase 1's "Be aggressive. Be creative. Refuse to give up." replaced with a concrete try-several-loops instruction |
| `vendor-auto/domain-modeling` | `skills/engineering/domain-modeling` | none |
| `vendor-auto/implement` | `skills/engineering/implement` | model-invoked locally: upstream's `disable-model-invocation` dropped. Adds "Use /agent-fleet when the work splits into independent tracks." Review step calls the Skill tool with `review-code` in `quick` mode, passing the spec path, and fixes every Blocker and Major finding |
| `vendor-auto/prototype` | `skills/engineering/prototype` | none |
| `vendor-auto/tdd` | `skills/engineering/tdd` | `code-review` reference renamed to `review-code` |
| `vendor-auto/grilling` | `skills/productivity/grilling` | extended with "Frame the questions that need it", "Keep a decision log" (`references/decision-log.md`) and "Close with a handoff" (`references/handoff.md`) |
| `vendor-auto/writing-for-agents` | `skills/productivity/writing-for-agents` | none |
| `dev/research` | `skills/engineering/research` | none |

## Related, not tracked

- `vendor/design-interface`: forked from upstream's former `design-an-interface`. Upstream folded it into `skills/engineering/codebase-design/DESIGN-IT-TWICE.md`. Compare for ideas, never overwrite.
- `vendor-auto/resolving-merge-conflicts`: upstream removed it in v1.3. Kept locally on purpose.
- `skills/review-code`: independent design that took over upstream `code-review`'s role. Compare for ideas, never overwrite.
- `vendor/show-me`: credited to humanlayer, not upstream. Upstream's `skills/engineering/pr` adapts its Summary visuals and overlaps `skills/pr-template`. Compare for ideas.
- `skills/agent-fleet`: overlaps upstream's `skills/in-progress/chief-of-staff` (one session coordinating subagents toward a long-running goal). Compare for ideas.
