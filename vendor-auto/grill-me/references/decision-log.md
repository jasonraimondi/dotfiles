# Decision log template

The durable record of a grill. Written continuously, not at the end. Keep it concise enough to paste into a future session as context — link out to artifacts (ADRs, specs, diffs, PRs) rather than restating them.

Save it to a findable path in the repo — `docs/grill/<topic>.md` (create the dir) — so a future session can load it. If not in a repo, use `mktemp -t grill-<topic>.md`. Keep one file and append; don't fork a new one per turn.

---

# Grill: <topic>
_Status: in progress · updated as we go_

## Decisions
Each line: what was chosen, why, and what was rejected.
- **<decision>** — chose <X>. Because <reason>. Rejected <alternative> (<why not>).

## Open questions
- <question> — <what's blocking it, or what would close it>

## Assumptions to validate
- <assumption> — <why it matters if wrong, how to confirm>

## Research
- <topic> — <the question, why it matters> · <finding, or "pending">

## Captured ideas (out of scope)
- <idea> — <motivation, constraints, open questions> — enough to start a future grill cold.
