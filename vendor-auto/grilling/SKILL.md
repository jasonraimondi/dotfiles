---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea — round-based, tree-structured questioning that keeps every decision with the user and ends in an implementation-ready handoff. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

**The decisions are the user's.** Recommend, argue, push back — never decide silently or act on your own read. Do not write implementation until the user explicitly approves moving past the grill.

## Work the tree in rounds

The **frontier** is every decision whose prerequisites are already settled — the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Each question should be formatted like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Each round the user answers reshapes the tree — settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one. Prune branches that earlier answers made irrelevant — don't ask them.

### Frame the questions that need it

Don't assume the user recognises every library, pattern, or term. When a question turns on something they may not know, or carries a tradeoff worth seeing, expand its body before asking them to choose: where it sits in the existing system, what rides on the choice, the realistic options with their costs, and a minimal sketch of each proposal — likely files, interfaces, responsibilities, and where they plug in. Label a sketch as illustration, not final code.

Expand only the questions that earn it. Framing every question identically buries the ones that matter.

## Facts are your job, decisions are the user's

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, docs), dispatch a sub-agent to find it — don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report — ask the rest of the frontier now.

## Keep a decision log

Start a **decision log** once the first decision lands and append to it every round — decisions and their reasons, rejected alternatives and why not, open questions, assumptions to validate, research findings, and captured ideas. Follow [`references/decision-log.md`](references/decision-log.md). It lives outside the repo — never commit it. Keep it tight enough to paste into a future session as context.

When a round surfaces something valuable but out of scope, capture it in the log — motivation, constraints, open questions, enough to start a future grill cold — and return to the frontier. Don't let it annex the session.

## Close with a handoff

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Produce an implementation-ready **handoff** following [`references/handoff.md`](references/handoff.md): acceptance criteria, approach, files and patterns, interface skeletons, constraints and non-goals, ordered tasks, required tests, and the decisions still needing the user.

Then stop. Do not act on it until the user confirms you have reached a shared understanding and approves moving past the grill.
