# Pi fleets

Pi peers use our local **pi-peer** extension, not pi-intercom or pi-subagents. It exposes `peer_sessions` with `self`, `list`, and `send`. Every participating session, including the coordinator, must load it.

## Setup

The extension lives at `pi/extensions/pi-peer/` in this repository. Install its production dependencies with `npm ci --omit=dev --ignore-scripts` from that directory. Link the directory into `~/.pi/agent/extensions/pi-peer`, or load its `index.ts` explicitly with `pi --extension /absolute/path/to/index.ts`. Respect `PI_CODING_AGENT_DIR` if the user has a custom config directory.

The repo's `setup.sh` installs the extensions directory alongside the skills, but also updates other configuration. Use a targeted link when only installing pi-peer; do not overwrite an existing installation without checking it. Restart or `/reload` after installation. The current session cannot gain a new tool merely by reading this skill.

Confirm:

```text
peer_sessions({ action: "self" })
peer_sessions({ action: "list" })
```

A tool named `intercom` is not a substitute. It may be a supervisor channel that only addresses managed children.

## Launch

```bash
python3 scripts/spawn-fleet.py --harness pi reviewer:/path/to/project
```

The script launches `herdr agent start ... --kind pi`, passes the local extension explicitly, and waits for a protocol handshake from peers in the panes it created. `--model` selects a pi model; `--agent-arg=<flag>` passes native options. Claude-only permission flags are rejected. The launcher does not set `--approve` or weaken tool restrictions.

Pi project trust, tool allowlists, and any permission extensions continue to apply. `peer_sessions` must be active. If it is excluded at startup, the session does not register. If disabled later, inbound messages are rejected. Do not alter restrictions merely to make a denied task run elsewhere.

## Send and reply

Addresses look like `pi:<instance-uuid>`. They identify one extension lifetime, not a name, conversation, or PID. Names may be duplicated. Always use an address from a fresh listing.

```text
peer_sessions({ action: "send", to: "pi:<worker-instance>", message: "Review only; do not edit. Return findings to pi:<coordinator-instance> using peer_sessions send. Reply once when done." })
```

Messages are displayed and stored as labeled peer messages. An idle recipient starts a turn; a busy one receives a follow-up after its current work finishes. This is not an interrupt or human approval. Use another nonblocking `send` to reply. Do not send acknowledgment loops.

`accepted` means handed to Pi's message queue, not executed or completed. Delivery errors can be ambiguous; inspect the peer before retrying. An explicit retry may reuse `messageId` to avoid reinjection while it remains among the receiver's last 1024 accepted messages. There are no automatic retries, blocking asks, or offline mailboxes.

## Discovery and recovery

```bash
python3 scripts/peer-addr.py --harness pi --me --json
python3 scripts/peer-addr.py --harness pi --name reviewer --details
```

Discovery performs a versioned handshake, not just a PID check. Stale crash records are ignored. Registry and socket files default to `/tmp/pi-peer-<uid>/`, require owner-only access, and disappear on clean shutdown. `PI_PEER_DIR` or pi's `--peer-dir` can select a short private directory; use the same directory for the coordinator, peers, and discovery script. Set `PI_PEER_DIR` for scripts when using a custom directory.

Reload, `/new`, `/resume`, and `/fork` replace the endpoint. Rediscover after each. Names update without changing the current endpoint. `/fork` or `pi --fork <session-file-or-id>` creates a separate conversation; never share one writable session file between two live peers.

For transcript recovery, inspect the receiver's pi session file for `customType: "pi-peer"` entries. Messages store `messageId` and `sender` details. The Claude-only `peer-inbox.py` does not parse pi history. A local user can edit their own transcripts and registry; metadata is not cryptographic evidence.

## Scope and limitations

macOS/Linux, same machine, same OS user. Socket permissions keep other users out; same-user processes are trusted, not sandboxed from one another. The protocol cross-checks the sender's live endpoint but does not authenticate a potentially hostile process with the same UID. Peer identity never grants additional authority.

Only messaging lives in the extension. Herdr owns layout; the skill owns coordination. Mixed Claude/pi messaging, remote hosts, durable offline delivery, and fleet dashboards are outside this version.
