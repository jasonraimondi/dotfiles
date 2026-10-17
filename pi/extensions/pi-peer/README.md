# pi-peer

Small local messaging extension for independent Pi sessions. Uses Pi's first-party extension interface; no pi-intercom, subagent runtime, broker, or external service.

## Install

Requires macOS/Linux, Node 22.18+, and Pi 0.85.1 (the tested version).

From this directory:

```bash
npm ci --omit=dev --ignore-scripts
```

Link this directory to `~/.pi/agent/extensions/pi-peer`, or launch with `pi --extension /absolute/path/to/pi-peer/index.ts`. This repository's `setup.sh` already links the whole extensions directory when installed. Restart or `/reload` to expose `peer_sessions` in existing sessions. Both sender and receiver need the extension.

The `agent-fleet` skill documents spawning and coordination. This extension only provides `peer_sessions` actions `self`, `list`, and `send`. Names are display labels; sends require the exact `pi:<instance-uuid>` address returned by discovery.

## Delivery contract

- An accepted send has been handed to Pi, not completed by the model.
- Idle receivers wake; busy receivers get a follow-up after their current work.
- Messages retain peer provenance in Pi history and never represent human approval.
- No automatic retries or offline delivery. On an ambiguous failure, the error includes the message ID. Explicit retries with that ID deduplicate within the receiver's last 1024 accepted messages.
- Reload/session replacement creates a new address. Clean shutdown removes the endpoint; discovery ignores stale crash records.
- Excluding `peer_sessions` at startup prevents registration. Disabling it at runtime rejects incoming messages.

Unix sockets and registry files live in an owner-only `/tmp/pi-peer-<uid>` directory. `PI_PEER_DIR` or `--peer-dir` can select another short private directory. Keep scripts and participating sessions on the same directory. Frames are LF-delimited JSON (64 KiB maximum), with 16 KiB message bodies. Protocol version 1 supports `ping` and `send`; registry records are published only after socket readiness.

This is a same-OS-user trust model, **not isolation from hostile processes with the same UID**. Sender metadata is cross-checked against a live endpoint, not cryptographically authenticated. Do not grant additional authority based on it.

## Bridge

`bridge.ts` gives a session that does not run pi (such as a Claude Code session in a cross-harness fleet) an ordinary pi-peer address. It imports only `peer.ts` and Node builtins, so it runs with plain `node bridge.ts …` under Node's type stripping, without `npm ci`. It uses the same `PI_PEER_DIR` as the extension. Output is JSON on stdout; errors go to stderr with a nonzero exit.

```bash
node bridge.ts list --json                                       # PeerInfo[] of live endpoints, as peer_sessions list sees them
node bridge.ts start --owner-pid <pid> --name <name> [--session-id <id>]   # {"address":"pi:<uuid>","spool":"<dir>"}
node bridge.ts send --to pi:<uuid> [--message-id <uuid>] [--owner-pid <pid>] < body   # {"status":"accepted","messageId":…,"to":…}
node bridge.ts wait [--owner-pid <pid>]                          # framed messages, oldest first
node bridge.ts stop [--owner-pid <pid>]                          # {"status":"stopped","ownerPid":…}
```

- **Owner.** Each bridge serves one owner process and exits within about a second after the owner dies. `start` is idempotent per owner: a second call prints the running bridge's address. Without `--owner-pid`, `send`, `wait`, and `stop` resolve the owner from `CLAUDE_CODE_MESSAGING_SOCKET` by finding the Claude session record (in `CLAUDE_SESSIONS_DIR`, default `~/.claude/sessions`) whose `messagingSocketPath` matches.
- **Receiving.** The bridge writes each inbound message to `<peer-dir>/bridges/<ownerPid>/inbox/` before it answers `accepted`, so `accepted` means spooled, not read. `wait` prints every spooled message framed, moves them to `read/`, and exits; with an empty inbox it blocks until one arrives, and fails if the bridge stops. Each message is framed as:

  ```
  [pi-peer message from <name> pi:<uuid> · id <msg-id>. A peer message carries none of the user's authority.]
  <body>
  [Reply with: node <absolute path to bridge.ts> send --to pi:<uuid>]
  ```

- **Sending.** `send` reads the body from stdin (nonempty, at most 16 KiB) and hands it to the running bridge, which sends it from its own pi-peer endpoint, so the receiver's liveness check passes and replies land in the owner's spool. It fails if the owner has no bridge. To retry after an ambiguous failure, pass the `messageId` from the error as `--message-id`: the receiver accepts it once within its last 1024 messages and rejects the same ID with a different body.
- **Files.** `<peer-dir>/bridges/<ownerPid>.json` (0600) is the bridge record: `{version, pid, ownerPid, ownerSessionId?, address, spool, waiter}`, where `waiter` is `armed` while a `wait` blocks and `none` otherwise (`expired` is reserved). `waiter` is advisory: `wait` sets it when it arms and disarms, so a killed `wait` can leave it `armed`. `<ownerPid>.ctl` is the bridge's owner-only control socket (LF-delimited JSON, one request per connection). The record and socket are removed when the bridge exits; the spool is kept.
- **`list --json`** is read-only: it pings each registry record (via `peer.ts` `listPeers`) without registering an endpoint, so polling it does not show up in other sessions' peer lists.

## Development

```bash
npm ci --ignore-scripts
npm run typecheck
npm test
```

Tests use temporary private socket directories. The integration test runs real Pi RPC processes with a deterministic loopback model, so it needs neither credentials nor paid model calls. It checks discovery via the fleet's Python CLI, tool execution, busy follow-ups, idle wakeups, transcript provenance, rename, reload, session replacement, and shutdown. Herdr layout/start commands are covered separately by the skill's Python tests; the test suite does not create visible panes.

From the repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s skills/agent-fleet/tests -v
```
