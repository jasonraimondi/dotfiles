# Manifest

Last-synced upstream commit: `4ae2317` (post-v1.3.2, 2026-10-31)

Local paths are relative to `skills/` in the dotfiles repo; upstream paths are relative to the upstream repo root.

## Tracked

| Local | Upstream | Kept divergence |
|---|---|---|
| `vendor-pending/claude-handoff` | `skills/in-progress/claude-handoff` | parked in `vendor-pending/` (not installed) |
| `vendor-mattpocock/grill-me` | `skills/productivity/grill-me` | none |
| `vendor-mattpocock/grill-with-docs` | `skills/engineering/grill-with-docs` | none |
| `vendor-mattpocock/handoff` | `skills/productivity/handoff` | saves to the notebook's `handoff/` through the notebook skill, not the OS temp dir |
| `vendor-mattpocock/teach` | `skills/productivity/teach` | none |
| `vendor-mattpocock/to-questionnaire` | `skills/productivity/to-questionnaire` | none |
| `vendor-mattpocock/wait-what` | `skills/productivity/wait-what` | none |
| `vendor-mattpocock/wizard` | `skills/engineering/wizard` | none |
| `vendor-mattpocock/codebase-design` | `skills/engineering/codebase-design` | none |
| `vendor-mattpocock/diagnosing-bugs` | `skills/engineering/diagnosing-bugs` | Phase 1's "Be aggressive. Be creative. Refuse to give up." replaced with: try at least two more loops from the list before falling back to reading code |
| `vendor-mattpocock/domain-modeling` | `skills/engineering/domain-modeling` | none |
| `vendor-mattpocock/implement` | `skills/engineering/implement` | model-invoked locally: upstream's `disable-model-invocation` dropped. Adds "Use /agent-fleet when the work splits into independent tracks." Review step calls the Skill tool with `deep-review-code` in `quick` mode, passing the spec path, and fixes every Blocker and Major finding |
| `vendor-mattpocock/prototype` | `skills/engineering/prototype` | none |
| `vendor-mattpocock/tdd` | `skills/engineering/tdd` | `code-review` reference renamed to `review-code` |
| `vendor-mattpocock/grilling` | `skills/productivity/grilling` | extended with "Frame the questions that need it", "Keep a decision log" (`references/decision-log.md`) and "Close with a handoff" (`references/handoff.md`). Upstream's "Word each question so \"yes\" accepts your recommended answer." stays out on every sync: the user takes recommendations by saying "accept recommendations", so questions keep whatever wording fits them |
| `vendor-mattpocock/review-code` | `skills/engineering/code-review` | renamed: frontmatter `name` is `review-code` |
| `vendor-mattpocock/writing-for-agents` | `skills/productivity/writing-for-agents` | none |
| `vendor-mattpocock/research` | `skills/engineering/research` | saves to the notebook's `research/` through the notebook skill, not the repo (description and step 3) |
| `vendor-mattpocock/retro` | `skills/engineering/retro` | none |

## Related, not tracked

- `vendor-auto/resolving-merge-conflicts`: upstream removed it in v1.3. Kept locally on purpose.
- `vendor/show-me`: credited to humanlayer, not upstream. Upstream's `skills/engineering/pr` adapts its Summary visuals and overlaps `personal/pr-template`. Compare for ideas.
- `personal/agent-fleet`: overlaps upstream's `skills/in-progress/chief-of-staff` (one session coordinating subagents toward a long-running goal). Compare for ideas.
