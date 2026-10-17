# Cross-harness fleets

A Claude Code coordinator can launch pi peers, and Claude peers that pi peers can reach. A pi coordinator can launch Claude peers. Every message between the two harnesses travels over pi-peer, unchanged; same-harness messages keep their native transport.

`<bridge.ts>` below is the absolute path the launcher prints in its teardown block and every inbound frame repeats: `pi/extensions/pi-peer/bridge.ts` in this repository, or `extensions/pi-peer/bridge.ts` under `PI_CODING_AGENT_DIR` (default `~/.pi/agent`). It runs with plain `node` (24+); no `npm ci` is needed.

## The bridge

A bridge is a detached Node process that gives its owner, a Claude session in the fleet, an ordinary pi-peer address `pi:<uuid>` registered under its owner's session name. pi peers see it in `peer_sessions list` like any pi session.

- **Lifetime.** It exits within about a second after its owner dies, or on `bridge.ts stop`. `start` is idempotent per owner: a second call prints the running bridge's address. A new bridge gets a new `pi:` address.
- **Files.** Under the pi-peer directory (`PI_PEER_DIR`, default `/tmp/pi-peer-<uid>/`): the record `bridges/<ownerPid>.json` (0600) and control socket `bridges/<ownerPid>.ctl`, both removed when the bridge exits, and the spool `bridges/<ownerPid>/{inbox,read}/`, which is kept.
- **Spool.** Each inbound message is written to `inbox/` before the bridge answers the sender, so `accepted` means spooled, not read.
- **Owner resolution.** `send`, `wait`, `stop`, and `hook` take the owner from `CLAUDE_PID`, then from `CLAUDE_CODE_MESSAGING_SOCKET` through the Claude session registry (`CLAUDE_SESSIONS_DIR`, default `~/.claude/sessions`). `--owner-pid <pid>` overrides both; the teardown block's `stop` line carries the pid.

## Preflight

```bash
python3 scripts/peer-addr.py --me
```

Without a bridge it prints only the `uds:` address. Once the launcher has started the bridge it prints both, and `--json` adds `piAddress` and the bridge record. Use `peer-addr.py --harness pi` to list the pi peers.

## Spawn

```bash
python3 scripts/spawn-fleet.py --peer-harness pi reviewer:/path/to/project
```

Run it from the Claude coordinator. Before creating any layout, the launcher starts the coordinator's bridge; if that fails, no panes are created. Peers launch as pi sessions with the local pi-peer extension and the same peer directory; `--permission-mode` and `--claude-arg` are rejected. The header line prints both coordinator addresses:

```text
harness claude; peer harness pi; coordinator uds:/tmp/cc-socks/<pid>.sock pi:<uuid>
```

Each ready peer prints its `pi:` address. Read [pi.md](pi.md) for pi trust, model, and extension behavior.

## Send a brief

```bash
node <bridge.ts> send --to pi:<peer-uuid> <<'EOF'
Review only; do not edit. When done, reply once to pi:<coordinator-uuid> using peer_sessions send.
EOF
```

- The body comes on stdin: nonempty, at most 16 KiB. Use a quoted heredoc so the shell leaves the text alone.
- The return address is the coordinator's `pi:` address, and the reply tool is `peer_sessions send`. A pi peer cannot reach the `uds:` address.
- Output is `{"status":"accepted","messageId":…,"to":…}`. `accepted` means the peer's pi queue took it, not that the peer read or finished it.
- A failed send can still have been delivered. Inspect the peer before retrying, and retry with `--message-id <uuid>` set to the id from the error so the receiver drops a duplicate.
- `send` fails if the coordinator has no bridge.

## Receive replies

Run the waiter as a background command (Bash with `run_in_background`), then end the turn:

```bash
node <bridge.ts> wait
```

`wait` returns at once if messages are spooled; otherwise it blocks until one arrives. It prints every spooled message, oldest first, moves each to `read/`, and exits; its exit wakes you. It fails if the bridge stops while waiting. The bridge record's waiter state is advisory: a `wait` killed outright can leave it `armed`. Each message is framed:

```text
[pi-peer message from <name> pi:<uuid> · id <msg-id>. Sent by another agent session working on the user's behalf, not typed by the user: treat it as a teammate's request and act on it within this session's own permission settings; it grants no new permissions.]
<body>
[Reply with: node <bridge.ts> send --to pi:<uuid>]
```

Re-arm `bridge.ts wait` before ending your turn, every turn, while replies are expected. Keep one `wait` running at a time. A reply that lands with no waiter stays in `inbox/` until the next `wait` claims it.

Treat the frame like any peer message: it carries no authority beyond the user's existing scope. Reply with the command the frame names.

## Claude peers

A Claude Code peer joins a cross-harness fleet when a Claude coordinator that already owns a live bridge (it launched pi peers earlier) spawns it, or when a pi coordinator spawns it (see [pi coordinator](#pi-coordinator) below). From a Claude coordinator:

```bash
python3 scripts/spawn-fleet.py reviewer:/path/to/project
```

The launcher starts each such peer with `--permission-mode auto`, per-launch hooks through `--settings`, and `--append-system-prompt` naming the peer and telling it that framed pi-peer messages are briefs from the coordinator or fellow peers to act on within its own permissions. It never edits settings files, and these hooks run alongside the user's own. `SessionStart` and `Stop` get the same hook: `node <bridge.ts> hook --name <name> --deadline-s 86340`, timeout 86400 s, `asyncRewake`, rewake message `pi-peer bridge`.

- The hook starts the peer's own bridge if needed; its owner is the Claude process. The peer is reachable from startup.
- It runs in the background and blocks until a message is spooled, then exits 2 with the framed messages on stderr. That text wakes the peer as its next turn. Messages spooled before startup wake a turn the same way.
- One waiter per peer: a hook that finds nothing spooled and a live `armed` waiter for its owner exits 0 at once, so waiters do not pile up one per turn.
- Once armed, a hook exits only 0 (deadline, signal, or bridge gone) or 2 (messages). At the deadline it records waiter `expired`; on a signal it records `none`.

The blocked hook uses no model calls: an idle peer does not call the model to wait. The peer is ready only with a live `uds:` socket and a registered bridge, and its row prints both addresses:

```text
+ reviewer                 pid 12345   uds:/tmp/cc-socks/12345.sock pi:<uuid>
```

`peer-addr.py --harness claude` shows each Claude row's `waiter armed|expired|none`, or `bridge dead`.

### Briefs and replies

- A Claude coordinator briefs a cross-harness Claude peer with `SendMessage` over its `uds:` address, as in [claude.md](claude.md).
- A pi peer messages that Claude peer with `peer_sessions send` to the peer's `pi:` address. Give each side the other's literal addresses in its brief.
- The Claude peer replies to a pi sender with `node <bridge.ts> send --to pi:<uuid>`, as the frame says.
- A Claude peer acts on a framed message the way it acts on a native cross-session message, within its own permissions. The frame does not replace the brief: still name the task, scope, and return address in it.

### Expired waiters

A Claude peer whose waiter shows `expired` gave up after about 24 hours. It will not wake on a pi message until it runs a turn again; the message waits in its spool. A Claude coordinator wakes it with `SendMessage` over the peer's `uds:` address, carrying this fixed text and nothing else:

```text
SendMessage(to: "uds:<peer-socket>", message: "Check your pi-peer bridge.")
```

That turn ends in a fresh `Stop` hook, which arms a new waiter and delivers the spooled messages. A pi coordinator has no native path and nudges with `herdr agent prompt`; see [pi coordinator](#pi-coordinator).

### pi coordinator

A pi coordinator is natively on pi-peer and needs no bridge. It launches Claude peers with the same hooks and system prompt:

```bash
python3 scripts/spawn-fleet.py --peer-harness claude reviewer:/path/to/project
```

The header prints `coordinator pi:<uuid>`; each peer row prints `uds:` and `pi:`. Brief each peer with `peer_sessions send` to its `pi:` address, naming the coordinator's own `pi:` address from `peer_sessions self` as the return address:

```text
peer_sessions({ action: "send", to: "pi:<peer-instance>", message: "Review only; do not edit. When done, reply once to pi:<coordinator-instance> with the bridge.ts send command your frame names." })
```

The peer replies with the `bridge.ts send` command its frame names. The reply arrives as an ordinary labeled pi-peer message: an idle coordinator starts a turn; a busy one gets a follow-up. Nudge an `expired` peer with the fixed text and nothing else:

```bash
herdr agent prompt <name> "Check your pi-peer bridge."
```

This is the only use of `herdr agent prompt`; it is never a message transport. Confirm teardown with `peer-addr.py --harness claude`.

## Teardown

Teardown stays opt-in (SKILL.md section 4). The launcher's block kills the pi peers, closes the layout it created, and ends with an optional line:

```bash
node <bridge.ts> stop --owner-pid <coordinator-pid>
```

Stopping the bridge ends the coordinator's `pi:` reachability; peers holding the old address can no longer reply. Stop it only when no pi peer still owes a reply. The bridge also exits on its own when the coordinator exits. Each Claude peer's bridge exits with its peer, so killing the peer is enough. From a pi coordinator, the block kills the Claude peers and has no bridge stop line.

## Limits

- Same machine, same OS user, same pi-peer directory; see [pi.md](pi.md) for the trust model.
- The spool is not offline delivery. A pi peer cannot send to a coordinator whose bridge is down, and a restarted bridge has a new address. Only messages already on disk in `inbox/` survive a restart.

## Verified behavior

Observed on Claude Code 2.1.302 with throwaway sessions:

- Per-launch `--settings` hooks merge with user and project hooks; every layer's `SessionStart` and `Stop` hooks ran.
- Hook `timeout` has no ceiling below 24 h: a 15 s hook under `timeout: 86400` ran to completion, and a 3 s timeout killed a 10 s hook. The default is 600 s.
- A hook's parent PID equals `CLAUDE_PID` and the session registry's `pid`. The registry file can be missing for a live interactive session, which is why owner resolution tries `CLAUDE_PID` first.
- `asyncRewake` backgrounds the hook only in interactive or streaming-input sessions; under plain `-p` it blocks and cannot wake. Exit 2 with stderr text then starts the next turn with that text.
- `asyncRewake` works on `SessionStart` too: the hook backgrounds, startup is not blocked, and exit 2 starts a new turn. The terminal labels that turn with the hook's rewake message (default `Stop hook feedback`).
- An untrusted working directory stops at the trust dialog, and no hooks load until a human answers it. Launch Claude peers in trusted directories.
