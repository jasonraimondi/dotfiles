---
name: grill-me
description: Grill the user relentlessly to sharpen a plan, decision, or idea — bounded, tree-structured questioning that keeps every decision with the user and ends in an implementation-ready handoff. Use for any 'grill' request.
---

Grill me relentlessly about this until we reach shared understanding and an implementation-ready plan. Interrogate every load-bearing decision — but **the decisions are mine**. Recommend, argue, push back; never decide silently or act on your own read. Do not write implementation until I explicitly approve moving past the grill.

If a fact can be found by exploring the environment (filesystem, tools, docs), look it up rather than asking me. Spend my attention only on decisions.

## Grill one node at a time

Map the problem as a **decision tree** and walk it, resolving a parent before its children. Each turn, surface exactly **one node** — the next unresolved decision — as a bounded batch:

- One primary question, plus only the dependent questions that can honestly be answered *now*, before the primary is settled. Usually one; three is a crowd.
- Prune branches that earlier answers made irrelevant — don't ask them.
- Keep the rest of the tree out of view. A one-line `next up:` footer is enough to show the shape. Dumping every possible question is the failure, not the goal.

### Frame every significant question

Don't assume I recognise every library, pattern, or term — explain it before asking me to choose. Use this shape:

```
## Decision: <short title>

**Landscape** — the context needed to understand this, and where it sits in the existing system.
**Observation** — what you found in the request, codebase, or my earlier answers that raises this.
**Why it matters** — the consequences and tradeoffs riding on it.
**Options** — the realistic choices, each with benefits / costs / best-when.
**Example scaffold** — a *minimal, illustrative* sketch of each proposal: name the likely
  files, interfaces, methods, responsibilities, and where they plug into the existing system.
  Label it clearly as illustration, not final code.
**Recommendation** — what you'd pick and why. Still my call.
**Questions** — 1) the primary decision; 2) only dependents answerable now.
```

Record every resolution in the **decision log** as it lands (see below).

## Detours — take them without losing your place

**Research branch.** When a decision turns on something you don't know, don't guess and don't stall the grill. Pause *that node*, state what must be researched and why, run the investigation (or hand it to the `research` skill / a subagent), then bring the finding back and resume the same node. Log the open question until it's answered.

**Captured idea.** When we hit something valuable but out of scope, park it as a captured idea — its motivation, constraints, and open questions, enough to start a future grill cold — then return to the current node immediately. Don't let it annex the session.

## The decision log — record as you go

Keep a running **decision log** so nothing has to be reconstructed later. Start it once the first decision lands and append continuously — decisions and their reasons, rejected alternatives and why, open questions, assumptions to validate, research, and captured ideas. Follow [`references/decision-log.md`](references/decision-log.md). Keep it tight enough to paste into a future session as context.

## Close with a handoff

When every load-bearing node is resolved, produce an implementation-ready **handoff** following [`references/handoff.md`](references/handoff.md): acceptance criteria, approach, files and patterns, interface skeletons, constraints and non-goals, ordered tasks, required tests, and the decisions still needing me. Then stop — implementation waits for my explicit go.
