---
name: fleet-grill
description: Grill a plan with a panel of agent-fleet peers (Opus + GPT Sol) that answer each round, settle the low-stakes questions, and escalate the rest to you.
disable-model-invocation: true
argument-hint: "<topic | plan path | decision log path> (empty: read the clipboard with pbpaste)"
---

# Fleet grill

Run a `/grilling` session where a **panel** of two peers answers each round first. The panel settles what it can; the user decides what it escalates. Load `grilling` and `agent-fleet` with the Skill tool before anything else. `grilling` owns the design tree, the frontier, the round format, the decision log, and the handoff. `agent-fleet` owns launch, messaging, and teardown. This skill changes only who answers.

This session is the coordinator. It computes the frontier, briefs the panel, merges replies, applies the escalation rule, keeps the decision log, and talks to the user. Peers answer and look up facts. The user owns every escalated decision.

## 1. Start

- A path under the notebook's `decisions/grills/` resumes that grill: read the log, rebuild the tree from its Decisions, and take its Open questions as the frontier.
- No argument with a grill already running in this conversation: take it over at its current frontier and keep its decision log.
- Anything else is a new grill on that topic. With no argument and no running grill, read it with `pbpaste`.

Keep one decision log per `grilling`. Tag each decision with who settled it: `(panel)` or `(user)`.

When `domain-modeling` is loaded, as in a `/grill-with-docs` session, keep its duties in this session: it alone edits `GLOSSARY.md` and ADRs, and peers only flag terms.

## 2. Launch the panel

Follow the `agent-fleet` preflight, then `references/cross-harness.md` → *Preflight*, *Spawn*, *Send a brief*. Without `$HC_TERMINAL_ID`, stop and tell the user the panel needs a herdr-core terminal.

From the `agent-fleet` skill directory, spawn in the directory the grill is about, `sol` first because it starts the coordinator's bridge:

```bash
python3 scripts/spawn-fleet.py --peer-harness pi sol:<dir>@openai-codex/gpt-6.1-sol:high
python3 scripts/spawn-fleet.py opus:<dir>@opus
```

Send each peer one standing brief:

- The topic, and the decision log path to read now and before each round.
- Read-only: read code and docs, run read-only commands, change nothing.
- Answer independently. Reply only to the coordinator.
- Per question: an answer, confidence (high, medium, low), `file:line` evidence for every fact, and `needs-user: <reason>` when the call belongs to the user under the escalation rule below (inline the rule).
- Then any branches the tree is missing, one line each.
- With `domain-modeling` loaded: the glossary path, and a one-line flag for each term an answer or question uses that conflicts with the glossary or is used loosely.
- ≤400 words per reply.
- The coordinator's literal return address and reply tool, per `agent-fleet`.

## 3. Run a round

1. Compute the frontier per `grilling` and draft a recommended answer for each question.
2. Send both peers the round number and the questions with your recommendations. Re-arm `bridge.ts wait` and end the turn.
3. When both replies are in, run every question through the escalation rule. It is **settled** by the panel or **escalated** to the user.
4. Take each missed branch the panel names: add it to the tree, merge it into an existing question, or capture it in the log as out of scope.
5. Log each settled decision with `(panel)` and the panel's reason.
6. With nothing escalated, start the next round at once. Otherwise send the user the round message and wait.

### Escalation rule

Escalate a question when any one holds:

- The peers split, either peer is low-confidence, or you disagree with them.
- It sets goals, scope, priorities, or taste, or accepts a cost or risk.
- It is hard to reverse.
- It touches a decision the user made or something the user said they care about.

The panel settles the rest.

### Round message

Two parts:

1. **Settled by panel**: every decision settled since the user's last reply, one line each as `S<n> — <decision> — <reason>`. `S` numbers run across the whole session. The user vetoes by number at any time.
2. **For you**: the escalated questions in `grilling`'s round format. When the peers split, show each peer's answer and evidence in one line apiece, above your recommendation.

A veto reopens that decision as a question for the user and returns every decision that hangs off it to the frontier.

## 4. Close

The grill closes when the frontier is empty and no veto is pending.

1. Write the handoff per `grilling`.
2. Send both peers the handoff path for one review: gaps, contradictions with the log, and facts the code disputes, with `file:line`, ≤400 words. A gap that needs a decision reopens the grill; fix the rest in the handoff.
3. Show the user the handoff path, its summary, and the list of `(panel)` decisions.
4. Tear down the panel and stop the bridge per `agent-fleet`, then confirm with `peer-addr.py`. Keep it only when the user asks.

Then stop, per `grilling`, until the user approves moving past the grill.
