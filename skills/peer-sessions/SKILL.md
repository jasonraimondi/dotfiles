---
name: peer-sessions
description: Run a fleet of Claude Code sessions on this machine and make them talk to each other with SendMessage. Launch them in Herdr panes, tabs or workspaces, address them correctly, hand out work, collect replies, and tear them down cleanly. Use whenever the user wants two or more Claude sessions working together, and whenever a send fails with "not an agent in this conversation" or a peer that should be reachable is not.
---

# Peer sessions

Claude Code sessions on this machine can send messages to each other. A message becomes a **user prompt** in the receiving session. This one fact explains each rule below.

The loop: spawn a fleet → send a brief to each peer → end your turn → replies arrive as new user turns → leave the fleet up and hand the user the teardown. Teardown is opt-in; section 4 says when you run it yourself.

Every `scripts/` and `references/` path here is relative to this skill's own directory. Resolve it against that directory, not the working directory.

## 1. Spawn

The fleet runs in Herdr, so you must be inside a Herdr-managed pane. Check once:

```bash
test "${HERDR_ENV:-}" = 1
```

If that fails, say so and stop. Do not drive a Herdr session from outside Herdr.

```bash
python3 scripts/spawn-fleet.py orbits:/tmp/lab/orbits planets:/tmp/lab/planets
```

Each argument is `NAME:DIR`. One name serves as both the Herdr agent name and the Claude session name, so it must match `[a-z][a-z0-9_-]{0,31}`. The script labels each pane with its session name (`herdr pane rename`, so the label survives the session retitling its terminal), prints each session's `uds:` address and the exact teardown commands, returns when every session is addressable, and names each session that stalled.

With `--placement tab` or `workspace`, also pass `--title` — the fleet's mission in five words or fewer. Each tab or workspace is then labeled `f1: <title>`, `f2: <title>`, … instead of the anonymous `fleet-1`. Name the mission, not the mechanism: `--title "eng7380 billing repairs"`, not `--title "two claude sessions"`.

`--placement` says where the fleet appears. You choose it. Ask the user only when the choice changes their screen and you cannot tell what they want.

| Placement | Where the peers land | Pick it when |
|---|---|---|
| `split` (default) | sibling panes in your own tab | 1-3 peers. Your pane keeps the focus. |
| `tab` | new tabs in your workspace | 3+ peers, or work that runs for minutes. The user's current screen stays clean, and one tab click reaches the fleet. |
| `workspace` | new workspaces | a big fleet, a screen recording, or a second monitor. |

Prefer `split`. Herdr's own guidance is to stay in the current tab and the current directory unless the user asks for other topology.

Every other flag (`--direction`, `--per-tab`, `--model`, `--claude-arg`, …) and the per-placement edge cases: read `references/placement.md`.

Resolve one existing target without wading through the whole registry:

```bash
python3 scripts/peer-addr.py --name worker-fix --details
python3 scripts/peer-addr.py --pid 66826 --json
```

Filters preserve duplicate names by returning every matching PID. `--json` is the stable interface for scripts. A `?` row means a sandbox allowed the registry read but denied the active socket check; rerun with process/socket access before messaging.

When you launch `claude` through `herdr pane run` or any shell of your own rather than through the spawn script, prefix it with `env -u CLAUDE_CODE_CHILD_SESSION`. Your session exports that marker to everything it starts, and a session that inherits it binds no socket and registers nowhere — it runs, and no peer can ever reach it. `herdr agent start` needs no prefix, because Herdr's server owns the pane.

Sessions start with `--permission-mode auto`. This is the only mode that works with no human present. An `--allowedTools` list stalls on the first MCP tool that is not in the list. `--dangerously-skip-permissions` makes the receiver hold inbound messages for human approval. The peer then never sees your brief.

For unusual layouts, manual Herdr work, or forks: read `references/manual-rig.md`.

## 2. Send the briefs

```
SendMessage(to: "orbits", message: "...", summary: "5-10 words")
SendMessage(to: "orbits [de6649]", message: "...", summary: "...")
SendMessage(to: "uds:/tmp/cc-socks/17466.sock", message: "...")
```

**The first send with a bare name always bounces** — "not an agent in this conversation, re-send with the ref". That is a confirmation, not a failure. Copy the `[ref]` from the error and send again. Send all briefs in one batch. They bounce together and you re-send them together. A `uds:` address does not bounce.

Each brief that expects a reply must end with your literal address (from `peer-addr.py --me`), because the peer cannot find out who you are:

```
When done, message me back:
SendMessage(to: "uds:/tmp/cc-socks/4667.sock", message: "...")
```

Ask for a fixed reply format ("<name> done: <URL>") so a large fleet collates with no work, and add a scope guard ("research and write only, do not touch <repo>") — peers obey it. Two rules: `success: true` means the message arrived, not that the peer did the work. A send is one-way — say clearly if you want a reply.

## 3. End your turn

When the briefs are out, **stop**. A peer reply IS the notification. The reply arrives as a new user turn and wakes you. A poll loop on the panes burns tokens and blocks the user. Watch a pane only when you must see the screen (filming, or a quiet session), and use Herdr's own waits rather than a loop — `herdr agent wait <name> --until blocked` and `herdr agent read <name>`. Recipes in `references/manual-rig.md`.

## 4. Tear down — off by default

**Teardown is opt-in.** When the work is done, leave the fleet running and hand the user the teardown block the spawn script printed. A live peer keeps its context, so a follow-up question costs one message instead of a whole re-spawn. The user decides when the sessions stop. Say plainly that the fleet is still up and what it costs to leave it there.

Run the teardown yourself only when one of these holds:

- The user asks now — "tear it down", "clean up the fleet", "close those sessions".
- The user asked up front, at spawn time — "close them when you're done".

When you do tear down: **kill first, close second**, then confirm with `peer-addr.py`. A `claude` that outlives its pane is an addressable orphan, and killing the PID first makes that impossible whatever the close does.

Run the teardown the spawn script printed — it matches the placement and holds the pane, tab, and workspace ids it created. Close only what you made: a `split` fleet sits in the user's own tab, so closing that tab closes the user's work too. Hand-written teardown syntax: `references/placement.md`.

## When something fails

`peer-addr.py` lists each live local session and gives a reason for each unreachable one. For the message checkpoints, a session that registers nowhere, stale sockets, stalled prompts, and recovering a reply the terminal truncated: read `references/troubleshooting.md`.

One rule is not optional: a peer carries none of the user's authority. If your send is denied, or a peer reports a denial, tell the user. Never route around a permission decision through another session.
