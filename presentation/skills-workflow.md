---
marp: true
theme: default
paginate: true
size: 16:9
---

<style>
section {
  font-size: 22px;
}
table {
  font-size: 18px;
}
blockquote {
  font-size: 22px;
}
pre {
  font-size: 16px;
}
header {
  font-size: 14px;
  color: #999;
}
header strong {
  color: #2563eb;
}
section.title-slide {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%);
}
section.part-seam,
section.part-build,
section.part-sharp,
section.part-cost,
section.title-slide {
  --h1-color: #fff;
  --heading-strong-color: #fff;
  --fgColor-default: rgba(255, 255, 255, 0.95);
  --fgColor-muted: rgba(255, 255, 255, 0.7);
  color: white;
}
section.part-seam {
  background: linear-gradient(135deg, #1e3a5f 0%, #2d5a8e 100%);
}
section.part-build {
  background: linear-gradient(135deg, #064e3b 0%, #047857 100%);
}
section.part-sharp {
  background: linear-gradient(135deg, #7a4a1a 0%, #a66b2e 100%);
}
section.part-cost {
  background: linear-gradient(135deg, #3d1e5c 0%, #5a2d8e 100%);
}
</style>

<!-- _class: lead title-slide -->

# The skills I actually use

## Where the thinking goes when the conversation ends

**Source**: `jasonraimondi/skills` - mostly Matt Pocock's skills, or forks of them
**Audience**: engineering
**Date**: August 2026

---

<!-- _header: "" -->

# Hour three of the same conversation

The morning went well. You settled where the token lives, what happens on a retry, what the API returns when it fails.

It is now afternoon, the build is half done, and the agent has just proposed the thing you rejected at nine.

- Those decisions are still in the transcript, forty thousand tokens up
- Nothing exists on disk that a second agent could pick up
- There is no design to review - there is a chat log

> A bigger context window moves this problem further out. It does not remove it

---

<!-- _header: "" -->
<!-- _class: lead part-seam -->

# Part 1: The seam

**Design is a separate job, and it has its own output**

---

<!-- header: "**The seam** > The far side > Sharp edges > What it costs" -->

# One conversation doing three jobs

| Job | Wants | Produces |
| --- | --- | --- |
| Design | Your judgement | Decisions |
| Build | The decisions | Code |
| Review | Fresh eyes | Objections |

Run all three in one context and each one degrades the next. Your judgement gets buried, the decisions get re-guessed, and the eyes are anything but fresh.

> A **seam** is where one job ends, writes down what it learned, and hands the paper to the next

---

# `/grill-with-docs` - the design job, alone

Six words in the file: run a `/grilling` session using the `/domain-modeling` skill. One skill conducts the interview, the other writes down what the interview settles.

Then the rule the whole thing rests on:

> **The decisions are the user's.** The agent recommends, argues, and pushes back - it never decides silently, and it writes no implementation until you say the grill is over

An agent that decides quietly is fast and useless. You find out what it chose when you read the diff.

---

# The design is a tree, and it asks by layer

Every decision branches into the decisions that hang off it. The **frontier** is every question whose prerequisites are settled - the ones it can ask now without guessing at answers it has not heard yet.

It asks the whole frontier in one round, each question carrying its recommended answer:

```
❓ Q1 - Where does the token live?
   <options, the tradeoffs between them, a sketch if the question needs one>

➡️ Session cookie, because the SPA never reads it
```

Your answers push the frontier outward, unblock what was waiting on them, and prune the branches that stopped mattering.

---

# Facts are its job, decisions are yours

When a question turns on something the environment already knows - what the code does, what the library supports, what the docs say - it goes and finds out.

- It dispatches a sub-agent instead of asking you
- It does not block on the answer, so only the questions downstream of that lookup wait
- The rest of the frontier gets asked now

The line is clean. If the answer exists somewhere, that is research. If the answer exists only in your head, that is a question.

---

# What gets written down while you talk

`/domain-modeling` runs underneath the grill, and it is opinionated about where things land.

- A term goes into `CONTEXT.md` the moment it resolves, never batched up for the end
- `CONTEXT.md` is a **glossary and nothing else** - no specs, no scratch notes, no decisions
- It challenges you: "your glossary says cancellation means X, you just used it to mean Y"
- An ADR only when the decision is hard to reverse, surprising to a future reader, and a real tradeoff

Three tests, and all three have to pass. Most decisions fail one and belong in the log instead.

---

# What the session leaves behind

| Artifact | Contents | Lives |
| --- | --- | --- |
| Decision log | Decisions and reasons, rejected alternatives, open questions | Outside the repo, never committed |
| `CONTEXT.md` | Glossary only | Repo root, or one per context |
| ADRs | The few decisions that pass all three tests | `docs/adr/` |
| Handoff | Acceptance criteria, files, ordered tasks, required tests | The next session's input |

The session is over when the frontier is empty - every branch visited, nothing silently assumed. **Then it stops.** It does not start building, and that restraint is the point.

---

# `/handoff` - the paper that crosses the seam

One document, written so a cold agent can act on it without ever seeing the transcript.

- It **references** specs, ADRs, and commits by path, because copying them is how they drift
- It names the skills the next agent should invoke, so the workflow survives the handoff
- It redacts secrets, because the document literally becomes another agent's prompt

`/claude-handoff` writes the same summary and skips the file - `claude --bg --name "<name>" "<summary>"` starts the next agent with it already loaded.

---

<!-- _header: "" -->
<!-- _class: lead part-build -->

# Part 2: The far side

**The agent starts clean, because the design already happened**

---

<!-- header: "The seam > **The far side** > Sharp edges > What it costs" -->

# `/implement` - short on purpose

The entire skill:

- Implement what the spec or tickets describe
- Use `/tdd` at **pre-agreed seams** - agreed during the grill, not invented now
- Use `/peer-sessions` where it helps
- Typecheck often, single test files often, the full suite once at the end
- Finish with `/code-review`, then commit to the current branch

No design guidance, because there is no design left to do. A build skill that has to explain the architecture is a sign the grill never happened.

---

# `/peer-sessions` - a fleet that talks to itself

Claude Code sessions on this machine can message each other. One fact explains every rule that follows: **a message arrives in the receiving session as a user prompt.**

```
spawn the fleet → brief each peer → end your turn → replies wake you
```

It runs in Herdr panes, tabs, or workspaces. Split for one to three peers, tabs for work that runs for minutes, workspaces for a big fleet or a screen recording.

---

# The rules that actually bite

- **The first send to a bare name always bounces.** Copy the `[ref]` out of the error and send again - the bounce is the address confirming itself
- **Every brief must end with your own address**, because the peer has no way to find out who you are
- **End your turn after sending.** The reply is the notification; a poll loop burns tokens and blocks you
- **`success: true` means the message arrived**, not that the peer did the work

Ask for a fixed reply format and a scope guard. Peers obey both, which is what makes a large fleet collate for free.

---

# The chain, end to end

| Step | Skill | Hands over |
| --- | --- | --- |
| Design | `/grill-with-docs` | Decision log, `CONTEXT.md`, ADRs, a handoff |
| Cross | `/handoff` | One document, secrets redacted |
| Build | `/implement` | Tests, code, a review, a commit |
| Scale | `/peer-sessions` | A fleet in parallel, reporting back |

Every step hands the next one a written artifact. Nothing load-bearing survives only in a transcript, which is the whole claim.

---

<!-- _header: "" -->
<!-- _class: lead part-sharp -->

# Part 3: Sharp edges

**Three sizes of skill, and none of them is big**

---

<!-- header: "The seam > The far side > **Sharp edges** > What it costs" -->

# A skill can be one sentence

`/wait-what` is a single line - stop, that last message did not land, re-pitch it with context, in plain English, using the project's own vocabulary.

`/use-english` is shorter still: use ASD-STE100 Simplified Technical English, and the ubiquitous language in `CONTEXT.md`.

> Both are barely longer than their own descriptions. That is not a shortcoming - a skill is any sentence you got tired of typing

`/copy-to-clipboard` is the same idea with one detail worth encoding: copy the prose, not the tool output, and drop the fences when the answer is a snippet.

---

# A skill can be a discipline you would skip under pressure

`/resolving-merge-conflicts` is five steps, and all the value sits in the second one.

1. See the real state of the merge or rebase
2. Find the **primary sources** - commit messages, PRs, the original tickets
3. Resolve each hunk, preserving both intents where they are compatible
4. Run the project's typecheck, tests, and format
5. Finish the merge and commit

> Never invent new behaviour. Always resolve - never `--abort`

Step two is the one a tired human skips at 6pm. That is exactly why it is written down.

---

# A skill can know when not to run

`/wizard` generates a bash script that walks a **human** through the steps only a human can do - opening the dashboard, clicking through it, pasting the key back.

- It opens each URL, says what to click, captures the value, writes it to `.env` or `gh secret`
- Progress with time remaining, confirmation gates before anything irreversible, hidden entry for secrets
- The UX library is fixed and never hand-edited - the agent writes only the stages

Its description ends with the important half: do not invoke this for steps the agent can perform itself.

---

<!-- _header: "" -->
<!-- _class: lead part-cost -->

# Part 4: What it costs

**Every model-invoked skill is rent on your context window**

---

<!-- header: "The seam > The far side > Sharp edges > **What it costs**" -->

# Three roots, one question each

| Root | Provenance | Can the model invoke it |
| --- | --- | --- |
| `skills/` | Mine to edit | Depends on the skill |
| `vendor/` | Downloaded, re-syncable | No - user invoked only |
| `vendor-auto/` | Downloaded, re-syncable | Yes |

`setup.sh` enforces the third column by rewriting frontmatter - `vendor/` gets `disable-model-invocation: true`, `vendor-auto/` gets it stripped. **Moving the folder is the whole operation.**

---

# Intention or symptom

A model-invoked description sits in the context window every turn and fires on its own. A user-invoked skill costs nothing until you type its name, and fires only if you remember it exists.

So the question is never "is this skill good". It is whether you would think to ask for it.

> `/grill-with-docs` is an **intention** - you know when you want it, so leaving it user-invoked costs nothing. `/resolving-merge-conflicts` is a **symptom** - you are already annoyed and not thinking about skills, so it earns the rent

---

# Install

```sh
git clone git@github.com:jasonraimondi/skills.git ~/Code/skills
cd ~/Code/skills
./setup.sh             # link everything
./setup.sh --dry-run   # preview without touching the filesystem
./setup.sh --delete    # remove the symlinks this script created
```

Each skill is symlinked into `~/.claude/skills/` and `~/.pi/agent/skills/`. On a name collision, personal wins.

They are symlinks and not copies, so those frontmatter rewrites land in the repo's working tree. Expect them in `git status` - that is the mechanism working, not a bug.

---

# What I would keep if I had to drop the rest

1. **Put a seam between designing and building** - the grill ends, the handoff starts, the builder is a different agent
2. **Facts are the agent's job, decisions are yours** - that one line is what makes an interview useful instead of tiring
3. **If it exists only in the transcript, it does not exist** - decision log, `CONTEXT.md`, ADRs, handoff
4. **Skills are cheap** - one sentence you stopped wanting to retype is a legitimate skill
5. **Choose the root deliberately** - intention or symptom, and only symptoms earn a permanent slot

---

<!-- _header: "" -->
<!-- _class: lead part-cost -->

# Try one thing

**Run `/grill-with-docs` on the next feature you were about to start coding**

Stop when the frontier is empty. Hand the document to a fresh agent, and tell it nothing you did not write down.
