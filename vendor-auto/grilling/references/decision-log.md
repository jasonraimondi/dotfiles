# Decision log template

The durable record of a grill. Written continuously, not at the end. Keep it concise enough to paste into a future session as context — link out to artifacts (ADRs, specs, diffs, PRs) rather than restating them.

**Never write it into the repo.** It is working state, not a project artifact — don't create `docs/`, don't commit it, don't mention it in a commit.

Save it to `~/.claude/grills/<repo-or-project>-<topic>.md` (create the dir) so a future session can still load it. Keep one file and append; don't fork a new one per turn.

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
