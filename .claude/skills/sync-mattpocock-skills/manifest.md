# Manifest

Last-synced upstream commit: `d81f3a1` (v1.3, 2026-09-29)

Paths are relative to this repo (local) and to the upstream repo root (upstream).

## Tracked

| Local | Upstream | Kept divergence |
|---|---|---|
| `vendor/claude-handoff` | `skills/in-progress/claude-handoff` | none |
| `vendor/grill-me` | `skills/productivity/grill-me` | none |
| `vendor/grill-with-docs` | `skills/engineering/grill-with-docs` | none |
| `vendor/handoff` | `skills/productivity/handoff` | none |
| `vendor/teach` | `skills/productivity/teach` | none |
| `vendor/to-questionnaire` | `skills/productivity/to-questionnaire` | none |
| `vendor/wait-what` | `skills/productivity/wait-what` | none |
| `vendor/wizard` | `skills/engineering/wizard` | user-invoked locally: `disable-model-invocation: true` added |
| `vendor-auto/codebase-design` | `skills/engineering/codebase-design` | none |
| `vendor-auto/diagnosing-bugs` | `skills/engineering/diagnosing-bugs` | none |
| `vendor-auto/domain-modeling` | `skills/engineering/domain-modeling` | none |
| `vendor-auto/implement` | `skills/engineering/implement` | model-invoked locally: upstream's `disable-model-invocation` dropped. Adds "Use /peer-sessions where possible and helpful." Review step calls `/review-code quick` with the spec path and fixes every Blocker and Major finding |
| `vendor-auto/prototype` | `skills/engineering/prototype` | none |
| `vendor-auto/tdd` | `skills/engineering/tdd` | none |
| `vendor-auto/grilling` | `skills/productivity/grilling` | extended with "Frame the questions that need it", "Keep a decision log" (`references/decision-log.md`) and "Close with a handoff" (`references/handoff.md`) |
| `vendor-auto/writing-for-agents` | `skills/productivity/writing-for-agents` | none |
| `dev/research` | `skills/engineering/research` | none |

## Related, not tracked

- `vendor/design-interface`: forked from upstream's former `design-an-interface`. Upstream folded it into `skills/engineering/codebase-design/DESIGN-IT-TWICE.md`. Compare for ideas, never overwrite.
- `vendor-auto/resolving-merge-conflicts`: upstream removed it in v1.3. Kept locally on purpose.
- `skills/review-code`: independent design that took over upstream `code-review`'s role. Compare for ideas, never overwrite.
- `vendor/show-me`: credited to humanlayer, not upstream.
