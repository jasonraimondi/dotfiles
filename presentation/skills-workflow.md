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
section.part-workflow,
section.part-sharp,
section.part-close,
section.title-slide {
  --h1-color: #fff;
  --heading-strong-color: #fff;
  --fgColor-default: rgba(255, 255, 255, 0.95);
  --fgColor-muted: rgba(255, 255, 255, 0.7);
  color: white;
}
section.part-workflow {
  background: linear-gradient(135deg, #1e3a5f 0%, #2d5a8e 100%);
}
section.part-sharp {
  background: linear-gradient(135deg, #064e3b 0%, #047857 100%);
}
section.part-close {
  background: linear-gradient(135deg, #3d1e5c 0%, #5a2d8e 100%);
}
</style>

<!-- _class: lead title-slide -->

# The skills I actually use

## A workflow, not a catalog

**Source**: `jasonraimondi/skills`, mostly Matt Pocock's skills or forks of them
**Audience**: engineering
**Date**: August 2026

---

# What this answers

1. **Why one long conversation stops working** - and what to do instead
2. **What a grill session is** - and why the decisions stay with you
3. **How work moves between agents** - grill, handoff, implement
4. **How to run more than one agent** - without babysitting them
5. **Which small skills earn their keep** - the one-liners I reach for daily

---

<!-- _class: lead title-slide -->

# Agenda

### Part 1: The workflow
`/grill-with-docs` to `/handoff` to `/implement` to `/peer-sessions`

### Part 2: The sharp edges
Small skills that fix one thing well

### Part 3: How it holds together
Invocation split, install, takeaways

---

<!-- _header: "" -->
<!-- _class: lead part-workflow -->

# Part 1: The workflow

**Four skills, one chain - design, capture, build, fan out**

---

<!-- header: "**The workflow** > Sharp edges > How it holds together" -->

# The problem with one long conversation

You design, then you build, then you review - all in the same context.

- The design decisions scroll away
- The agent starts guessing at what you already settled
- Context runs out mid-implementation
- Nothing is written down that a second agent could pick up

> The fix is not a bigger context window. It is a **seam** between designing and building

---

# `/grill-with-docs` - design before code

Two skills stacked: it runs a `/grilling` session using `/domain-modeling`.

- **Grilling** interviews you relentlessly until you share an understanding
- **Domain modeling** captures the language while you talk - `CONTEXT.md` and ADRs

The one rule that makes it work:

> **The decisions are the user's.** The agent recommends, argues, pushes back - it never decides silently

---

# How a grill session runs

The design is a **tree**. Every decision branches into the decisions that hang off it.

- The **frontier** is every question whose prerequisites are already settled
- The agent asks the whole frontier in one round, each with a recommended answer
- Your answers push the frontier outward and prune the branches that no longer matter

```
❓ **Q1** - **Where does the token live?**: <options and tradeoffs>

➡️ Session cookie, because the SPA never reads it
```

---

# Facts are its job, decisions are yours

When a question needs a fact from the environment, the agent goes and gets it.

- It dispatches a sub-agent for filesystem, tool, or docs lookups
- It never asks you something it could look up
- It does not block - only the questions downstream of that lookup wait

Everything else on the frontier gets asked now.

---

# What a grill session leaves behind

| Artifact | Contents | Lives |
| --- | --- | --- |
| Decision log | Decisions and reasons, rejected alternatives, open questions | Outside the repo, never committed |
| `CONTEXT.md` | Glossary only - no implementation detail | Repo root, or per context |
| ADRs | Hard to reverse, non-obvious, still live decisions | `docs/adr/` |
| Handoff | Acceptance criteria, files, tasks, required tests | Next session's input |

The session ends when the frontier is empty. **Then it stops** - it does not start building

---

# `/handoff` - compact the conversation

Turns everything above into one document a fresh agent can read cold.

- Writes to `mktemp -t handoff-<description>.md`
- Includes a **suggested skills** section, so the next agent knows what to invoke
- References specs, ADRs, and commits by path - it does not copy them
- Redacts secrets, because the document becomes another agent's prompt

`/claude-handoff` is the same summary, but it launches the background agent for you with `claude --bg --name`

---

# `/implement` - the fresh agent builds it

Short skill, strong opinions:

- Implement what the spec or tickets describe
- Use `/tdd` at **pre-agreed seams** - agreed during the grill, not invented now
- Use `/peer-sessions` where it helps
- Typecheck often, single test files often, full suite once at the end
- Finish with `/code-review`, then commit to the current branch

The agent starts clean. The design already happened.

---

# `/peer-sessions` - a fleet that talks to itself

Claude Code sessions on this machine can message each other. A message arrives in the receiving session as a **user prompt**. Every rule follows from that.

```
spawn a fleet → brief each peer → end your turn → replies wake you
```

Runs in Herdr panes, tabs, or workspaces. `--placement split` for one to three peers, `tab` for longer work, `workspace` for a big fleet.

---

# The peer-session rules worth knowing

- **The first send with a bare name always bounces** - copy the `[ref]` from the error and send again. That is confirmation, not failure
- **Each brief must end with your own address**, because the peer cannot find out who you are
- **End your turn after sending.** A poll loop burns tokens and blocks you - the reply is the notification
- **`success: true` means the message arrived**, not that the peer did the work

Ask for a fixed reply format and a scope guard. Peers obey both.

---

# The chain end to end

| Step | Skill | Produces |
| --- | --- | --- |
| Design | `/grill-with-docs` | Decision log, `CONTEXT.md`, ADRs, handoff |
| Capture | `/handoff` | One document, secrets redacted |
| Build | `/implement` | Tests, code, review, a commit |
| Scale | `/peer-sessions` | A fleet working in parallel, reporting back |

Each step hands the next one a written artifact. Nothing important lives only in a transcript.

---

<!-- _header: "" -->
<!-- _class: lead part-sharp -->

# Part 2: The sharp edges

**Small skills that fix exactly one thing**

---

<!-- header: "The workflow > **Sharp edges** > How it holds together" -->

# `/wait-what` and `/use-english`

Two one-line skills for when the agent gets ahead of you.

**`/wait-what`** - stop, that last message did not land. Re-pitch it with context, in plain English, using the project's own vocabulary.

**`/use-english`** - use ASD-STE100 Simplified Technical English, and the ubiquitous language in `CONTEXT.md`.

> Both are barely longer than their descriptions. That is the point - a skill can be one sentence you got tired of typing

---

# `/copy-to-clipboard`

Pipes the turn's prose to `pbcopy` so you can paste it straight into Slack or a PR.

- Copies the **user-facing prose**, not the tool output or the diffs
- If the answer is a snippet, it copies the snippet without the fences
- One Bash call, single-quoted heredoc, so `$` and backticks pass through literally

macOS only. Triggers on "copy to clipboard", "/copy", "pbcopy this".

---

# `/domain-modeling`

The skill `/grill-with-docs` pulls in - useful on its own when the language is the problem.

- Challenges terms that conflict with the glossary already in `CONTEXT.md`
- Sharpens fuzzy words - "you said account, do you mean Customer or User?"
- Cross-references what you said against what the code does
- Writes `CONTEXT.md` inline as terms resolve, never batched

`CONTEXT.md` is a **glossary and nothing else** - no specs, no scratch notes, no implementation decisions.

---

# `/resolving-merge-conflicts`

Five steps, and the discipline is in steps two and three.

1. See the current state of the merge or rebase
2. Find the **primary sources** - commit messages, PRs, original tickets
3. Resolve each hunk, preserving both intents where possible
4. Run the project's typecheck, tests, and format
5. Finish the merge and commit

> Never invent new behaviour. Always resolve - never `--abort`

---

# `/wizard`

Generates a bash script that walks a **human** through steps only a human can do.

- Opens each URL, says what to click, captures the values, writes them to `.env` or `gh secret`
- Progress with time remaining, confirmation gates, hidden secret entry
- The UX library is fixed - the agent only writes the stages

Reach for it when provisioning infra or credentials. Not for anything the agent can do itself.

---

<!-- _header: "" -->
<!-- _class: lead part-close -->

# Part 3: How it holds together

**Provenance, invocation, install**

---

<!-- header: "The workflow > Sharp edges > **How it holds together**" -->

# Three roots, two questions

| Root | Provenance | Model can invoke it |
| --- | --- | --- |
| `skills/` | Mine to edit | Depends on the skill |
| `vendor/` | Downloaded, re-syncable | No - user invoked only |
| `vendor-auto/` | Downloaded, re-syncable | Yes |

`setup.sh` enforces the split by rewriting frontmatter: `vendor/` gets `disable-model-invocation: true`, `vendor-auto/` gets it stripped. **Moving the folder is the whole operation.**

---

# Which root does a skill belong in

The tradeoff is context load against recall.

- A **model-invoked** skill's description sits in the context window every turn, and fires on its own
- A **user-invoked** skill costs nothing until you type its name, and only fires if you remember it exists

> Reserve `vendor-auto/` for skills that trigger on a **symptom or a file type**, not on an intention you would think to name

`/grill-with-docs` is an intention. `/resolving-merge-conflicts` is a symptom.

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

Skills are symlinks, not copies - so frontmatter rewrites land in the repo's working tree. Expect them in `git status`.

---

# Takeaways

1. **Put a seam between designing and building** - the grill ends, the handoff starts
2. **The agent finds facts, you make decisions** - that is what keeps a grill useful
3. **Write it down or it did not happen** - decision log, `CONTEXT.md`, ADRs, handoff
4. **A skill can be one sentence** - `/wait-what` and `/use-english` are proof
5. **Choose the root deliberately** - every model-invoked description is rent on your context window

---

<!-- _class: lead part-close -->

# Try one thing

**Run `/grill-with-docs` on the next feature you were about to start coding**

Stop when the frontier is empty. Hand the result to a fresh agent.
