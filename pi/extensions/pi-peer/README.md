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
