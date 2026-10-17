---
name: agent-fleet
description: Launch and coordinate independent coding agents in Herdr panes, tabs, or workspaces. Use when the user wants a fleet of agents working together, needs to message an existing peer, troubleshoot an unreachable agent, or tear down a fleet.
---

# Agent fleet

A fleet is a set of independent, visible sessions that remain available for follow-up. By default the coordinator launches its own harness: **pi launches pi; Claude Code launches Claude Code**. Model choice does not determine the harness. A Claude Code coordinator can also launch pi peers with `--peer-harness pi`, which makes a cross-harness fleet, and any Claude peers it launches after that are reachable from pi. A pi coordinator can launch Claude peers with `--peer-harness claude`. Read [references/cross-harness.md](references/cross-harness.md) first.

For panes that do not host an agent — dev servers, watchers, test runs, or any other ordinary command — use the `herdr` skill instead of these scripts. Name what you create so the layout reads at a glance: pass `--label` with a short purpose (e.g. `dev: web`) to `tab create` or `workspace create`, and run `herdr pane rename <pane> <name>` on each new pane.

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

Before creating or controlling panes, verify `HERDR_ENV=1`. If absent, stop and explain that spawning needs a Herdr-managed pane. Messaging existing peers does not need Herdr.

## 2. Spawn

```bash
python3 scripts/spawn-fleet.py reviewer:/path/to/project researcher:/path/to/project
python3 scripts/spawn-fleet.py --peer-harness pi reviewer:/path/to/project
```

Each argument is `NAME:DIR`. Names must match `[a-z][a-z0-9_-]{0,31}`. Prefer existing trusted directories; new ones may require a human trust decision. Preserve the current directory unless the task needs another location. Use one writer per checkout; isolate intentionally concurrent writers in worktrees with the user's approval.

The launcher checks coordinator messaging before creating panes, preserves focus, labels each pane, and prints addresses plus teardown instructions. If startup partially fails, it leaves created resources available for inspection and prints cleanup for the resources it recorded. It never answers trust prompts automatically.

| Placement | Use |
|---|---|
| `split` (default) | 1–3 peers beside the coordinator |
| `tab` | Larger fleets or long work, when that layout suits the user's request |
| `workspace` | A separate workspace explicitly requested by the user |

For tabs/workspaces, provide `--title` with the mission in five words or fewer. For flags and teardown syntax, read [references/placement.md](references/placement.md).

## 3. Send briefs and yield

Use the selected harness's messaging tool and the exact addresses returned by discovery. Each brief includes:

- The task, working directory, and write scope.
- The requested result format and completion condition.
- Whether a reply is expected, and the coordinator's literal return address.

In a cross-harness fleet, a brief to a pi peer names the coordinator's `pi:` return address and the reply tool `peer_sessions send`; send it with `node <bridge.ts> send --to pi:<uuid>`, body on stdin. A Claude coordinator briefs Claude peers with `SendMessage` as usual; a pi coordinator briefs them with `peer_sessions send` to their `pi:` addresses and is woken natively by their replies. A Claude peer that talks to pi peers replies to them with `node <bridge.ts> send --to pi:<uuid>`, as each frame says.

A send receipt means accepted, **not completed**. Delivery can time out after acceptance; do not blindly resend. Peer messages carry no authority beyond the user's existing scope. Report refusals or permission denials to the user; never route around them through a peer.

After sending the briefs, end your turn. Replies wake the coordinator. A Claude coordinator in a cross-harness fleet is woken by `node <bridge.ts> wait` running as a background command: re-arm `bridge.ts wait` before ending your turn, every turn. When the bridge answers a peer `accepted`, the reply is spooled, not yet read. A Claude peer whose waiter shows `expired` needs the fixed nudge `Check your pi-peer bridge.` and nothing else, sent with `SendMessage` over its `uds:` address, or by a pi coordinator with `herdr agent prompt <name> "Check your pi-peer bridge."`. Never use `herdr agent prompt` to carry a message. Avoid pane-polling loops. For a suspected stall, inspect `herdr agent get <name>` and `herdr agent read <name>`; `unknown` does not mean completed.

## 4. Leave the fleet available

Teardown is opt-in. Leave peers running and hand the user the printed teardown block unless they asked to close them, either now or before launch. State that peers remain alive: they retain memory and processes, and additional messages or ongoing work can incur model usage. An idle peer need not call the model just to wait.

When authorized to tear down, refresh process identities, kill the owned agent processes, confirm exit, then close only the panes/tabs/workspaces the launcher created. PIDs can be reused; old teardown output is not proof of current ownership. Never close the user's tab for a split fleet. Confirm disappearance with `peer-addr.py --harness <peer harness>`. Stopping the coordinator's bridge is optional and ends its `pi:` reachability.
