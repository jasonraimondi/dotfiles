# Claude Code fleets

Claude Code peers use native `SendMessage`. Incoming messages prompt the receiver; they do not carry the user's authority. The local `pi-peer` extension is unrelated to this path.

## Preflight and launch

```bash
python3 scripts/peer-addr.py --harness claude --me --json
python3 scripts/spawn-fleet.py --harness claude reviewer:/path/to/project
```

Sessions default to `--permission-mode auto`. Bypass-permissions receivers can hold cross-session messages for human approval; prefer auto mode for this workflow. Auto mode can still deny tools, and fresh projects can still need human trust decisions. Never promise an unattended session cannot block.

When launching Claude through your own shell or `herdr pane run`, strip the inherited child-session marker:

```bash
env -u CLAUDE_CODE_CHILD_SESSION claude --name reviewer --permission-mode auto
```

A session that inherits that marker may bind no messaging socket or registry entry. `herdr agent start` launches through Herdr's server, rather than inheriting the coordinator's shell environment.

## Messaging

```text
SendMessage(to: "uds:/path/from/discovery.sock", message: "...", summary: "Review the proposed changes")
```

A bare name may bounce with a request to resend using the fresh `[ref]`. Copy the ref from the response rather than guessing. A direct `uds:` address avoids name confirmation. Refs and socket addresses change across process restarts.

Every brief expecting a reply includes the coordinator's literal address from `peer-addr.py --me`:

```text
When done, reply once:
SendMessage(to: "uds:<coordinator-socket>", message: "reviewer done: <findings>")
```

`success: true` confirms delivery, not task completion or model compliance. Send briefs, end the turn, and let replies wake the coordinator.

## pi peers

A Claude Code coordinator launches pi peers with `spawn-fleet.py --peer-harness pi`, briefs them with `bridge.ts send`, and is woken by `bridge.ts wait`. Claude peers it launches after that get bridge hooks so pi peers can wake them; a pi coordinator that launches Claude peers follows [cross-harness.md](cross-harness.md#pi-coordinator). Read [cross-harness.md](cross-harness.md) before launching.

## Troubleshooting and manual layouts

- [troubleshooting.md](troubleshooting.md): Claude messaging gates, stale sockets, missing replies, transcript recovery.
- [manual-rig.md](manual-rig.md): manual Herdr layouts and Claude conversation forks.

These references are Claude-specific. Read current CLI help before using version-sensitive commands. Recent Claude builds support `--bg`, `logs`, `stop`, and `attach` for background-managed sessions; those are not automatically applicable to interactive Herdr peers.
