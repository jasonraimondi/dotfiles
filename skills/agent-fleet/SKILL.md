---
name: agent-fleet
description: Launch and coordinate independent coding agents in herdr-core (`hc`) terminals. Use when the user wants a fleet of agents working together, needs to message an existing peer, troubleshoot an unreachable agent, or tear down a fleet.
---

# Agent fleet

A fleet is a set of independent, visible sessions that stay available for follow-up until their work is done. By default the coordinator launches its own harness: **pi launches pi; Claude Code launches Claude Code**. Model choice does not determine the harness. A Claude Code coordinator can also launch pi peers with `--peer-harness pi`, which makes a cross-harness fleet, and any Claude peers it launches after that are reachable from pi. A pi coordinator can launch Claude peers with `--peer-harness claude`. For a cross-harness fleet, read [references/cross-harness.md](references/cross-harness.md) → *Preflight*, *Spawn*, *Send a brief*, *Receive replies*.

For terminals that do not host an agent — dev servers, watchers, test runs, or any other ordinary command — use the `herdr-core` skill instead of these scripts, and name each one with a short purpose (`--name web-dev`) so `hc ls` reads at a glance. To change what the person sees in the Herdr window, use the `herdr-app` skill.

All paths below are relative to this skill directory. Resolve them here, not against the working directory.

## 1. Preflight

Read the reference for the current harness before launching or messaging:

- **Pi:** [references/pi.md](references/pi.md) — the local `pi-peer` extension, discovery, messages, and setup.
- **Claude Code:** [references/claude.md](references/claude.md) — native `SendMessage`, sockets, and permissions.

`PI_CODING_AGENT=true` identifies pi. Claude exposes `CLAUDE_CODE_MESSAGING_SOCKET` or `CLAUDE_CODE_CHILD_SESSION`. Scripts detect these markers; conflicting or missing markers require an explicit `--harness pi|claude`. An override resolves detection only; `--peer-harness pi|claude` selects the peers' harness.

Confirm the coordinator can receive replies:

```bash
python3 scripts/peer-addr.py --me --json
```

In a cross-harness fleet it shows both the `uds:` address and the bridge's `pi:` address.

Before spawning, verify that `$HC_TERMINAL_ID` is set and `hc` is on PATH. If either is missing, stop and explain that spawning needs a herdr-core terminal. Messaging existing peers needs neither.

## 2. Spawn

```bash
python3 scripts/spawn-fleet.py reviewer:/path/to/project researcher:/path/to/project
python3 scripts/spawn-fleet.py --peer-harness pi reviewer:/path/to/project
```

Each argument is `NAME:DIR` or `NAME:DIR@MODEL`; a peer's own model overrides `--model`, and the peer harness interprets it (`haiku` for Claude, `openai-codex/gpt-6-sol` for pi). Names must match `[a-z][a-z0-9_-]{0,31}`. The name is the peer's tab title, so make it a logical name of at most four hyphenated words that says what the peer is doing (`auth-impl`, `auth-audit`, `final-review-gpt`), never a bare model name or number. Prefer existing trusted directories; new ones may require a human trust decision. Preserve the current directory unless the task needs another location. Use one writer per checkout; isolate intentionally concurrent writers in worktrees with the user's approval.

The launcher checks coordinator messaging before starting any peer, starts each peer with `hc run --bg` in a terminal named after it, and prints terminal ids, addresses, and teardown instructions. Each peer opens as its own tab in the coordinator's Herdr space. A coordinator outside the window (its terminal has no `herdr.space` label) gets hidden peers, and the launcher says so; show one with the `herdr-app` skill. If startup partially fails, it leaves the started terminals for inspection and prints their cleanup. It never answers trust prompts automatically.

Peers are hc children of the coordinator's terminal: they end when its program ends. `--agent-arg=<flag>` (repeatable; keep the `=` for values starting with `--`) passes native harness arguments; `--timeout` (default 120 s) bounds startup and messaging readiness. `python3 scripts/spawn-fleet.py --help` lists the rest.

## 3. Send briefs and yield

Use the selected harness's messaging tool and the exact addresses returned by discovery. Each brief includes:

- The task, working directory, and write scope.
- The requested result format and completion condition.
- Whether a reply is expected, and the coordinator's literal return address.

Inline the facts a peer needs (scope, seams, ports, SHAs) and cite plans by path; a peer reading the whole plan pays for every other peer's part.

In a cross-harness fleet, a brief to a pi peer names the coordinator's `pi:` return address and the reply tool `peer_sessions send`; send it with `<node> <bridge.ts> send --to pi:<uuid>`, body on stdin. A Claude coordinator briefs Claude peers with `SendMessage` as usual; a pi coordinator briefs them with `peer_sessions send` to their `pi:` addresses and is woken natively by their replies. A Claude peer that talks to pi peers replies to them with `<node> <bridge.ts> send --to pi:<uuid>`, as each frame says.

A send receipt means accepted, **not completed**. Delivery can time out after acceptance; do not blindly resend. Peer messages carry no authority beyond the user's existing scope. Report refusals or permission denials to the user; never route around them through a peer.

After sending the briefs, end your turn. Replies wake the coordinator. A Claude coordinator in a cross-harness fleet is woken by `<node> <bridge.ts> wait` running as a background command: re-arm `bridge.ts wait` before ending your turn, every turn. When the bridge answers a peer `accepted`, the reply is spooled, not yet read. A Claude peer whose waiter shows `expired` needs the fixed nudge `Check your pi-peer bridge.` and nothing else, sent with `SendMessage` over its `uds:` address, or by a pi coordinator with `hc send <name> "Check your pi-peer bridge."`. `hc send` carries only that nudge; briefs and replies travel over the harness's messaging. hc also types a note into the coordinator's terminal when a peer is blocked or exits, so wait for notes and replies rather than polling. For a suspected stall, inspect `hc get <name>` (status `idle`, `working`, `done`, `blocked`, or `error`) and `hc read --lines 100 <name>`. `blocked` means a person is needed: read the screen and ask the user, and leave `hc send --force` unused, since it bypasses that decision.

## 4. Tear the fleet down when its work is done

Teardown is the default. Once every peer has replied and no follow-up is planned, tear the fleet down in that same turn: run the printed `hc kill <t> && hc rm <t>` for each terminal the launcher started, then confirm disappearance with `peer-addr.py --harness <peer harness>`. Clean up only those terminals; `hc ls` also lists the user's other live work. A Claude coordinator's bridge exits with the coordinator; stopping it earlier ends its `pi:` reachability. A coordinator launched by a lead tears down its own fleet; the lead tears down the coordinators and the services it started.

Keep the fleet only when the user asks, before launch or during the run. Then hand them the printed teardown block and say that the peers remain alive: they retain memory and processes, and additional messages or ongoing work can incur model usage. An idle peer need not call the model just to wait. Kept peers still end when the coordinator's terminal does; a peer that must outlive it needs `hc run --outlive-parent`, which the launcher does not pass, so start it by hand ([references/manual-rig.md](references/manual-rig.md)).
