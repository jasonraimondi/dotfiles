# Manual rigging, forks, and paths that the skill does not cover

Read this when `spawn-fleet.py` does not fit: a peer that must outlive the coordinator, filming, forks, or a `claude`/`hc` capability that the skill does not name. The `herdr-core` skill holds the full `hc` manual; the `herdr-app` skill changes the window layout.

## A peer by hand

This is what the launcher runs for each peer:

```bash
hc run --bg --json --name alpha --cwd /tmp/lab/alpha --label herdr.space=<space> \
  -- "$SHELL" -ilc 'exec "$0" "$@"' claude --name alpha --permission-mode auto
# → .address, e.g. t7
```

- `<space>` is the coordinator's own space: `hc get "$HC_TERMINAL_ID"` → `.labels["herdr.space"]`. The label opens the peer as its own tab there; without it the peer runs hidden.
- The interactive login shell wrapper restores the PATH a peer's tools expect. hc gives an explicit command only the bare login-session environment, with no mise shims and no pnpm bin.
- That bare environment also means a peer never inherits the coordinator's `CLAUDE_CODE_CHILD_SESSION` marker.
- The `--name` before `--` names the hc terminal; the `--name` after it binds the Claude session name that `SendMessage` and `peer-addr.py` resolve. Keep them identical.
- The peer is an hc child of your terminal and ends when your program ends. Add `--outlive-parent` before `--` for a peer that must survive you.

Teardown is the default once the work is done (SKILL.md section 4): `hc kill <t> && hc rm <t>` for each terminal you started.

## Watch the peers

```bash
hc ls                      # every live terminal, including the user's
hc get alpha               # state and status
hc read --lines 100 alpha  # screen plus history
hc wait alpha              # until it stops working or exits
hc wait --children any     # the next child's news, or a message to you
```

Read the status rather than guessing from the screen. Claude Code and pi report `idle`, `working`, `done`, `blocked`, or `error` natively; plain programs report none. `blocked` means a person is needed: read the screen and ask the user. `hc send` refuses a blocked terminal unless `--force`; leave that decision to the person.

A long reply that scrolled off the peer's screen lives in its transcript. Recover it with `scripts/peer-inbox.py`, in `troubleshooting.md`.

If you asked the peer to reply by `SendMessage`, end your turn instead of watching anything.

## Fork a session

`--fork-session` starts a peer from the history of an existing conversation, under a **new** session id:

```bash
hc run --bg --json --name reviewer-a --cwd <dir> --label herdr.space=<space> \
  -- "$SHELL" -ilc 'exec "$0" "$@"' claude --resume <sessionId> --fork-session --name reviewer-a --permission-mode auto
```

The fork starts with the full transcript and a fresh id. The original session continues, and you can address both. Without `--fork-session`, `--resume` uses the same id and the sessions collide.

Session id vs socket: the socket (`uds:...`) is the address of a running *process*. The session id is the address of a *conversation on disk*. Get your own id from `peer-addr.py --me`. Get another session's id from `sessionId` in `~/.claude/sessions/<pid>.json`.

To fork one session N ways is better than to write the same long brief N times.

## Worktrees

When the fleet edits one repo and the user asks for it, give each writer its own git worktree under `~/.herdr/worktrees/<org>/<name>`:

```bash
git worktree add ~/.herdr/worktrees/<org>/<name> -b <branch>
```

## When you need something that this file does not cover

Read the help. Do not guess. Do not assume a thing is impossible:

```bash
COLUMNS=200 claude --help    # a pipe through head kills it with SIGPIPE;
claude agents --help         # narrow terminals wrap it into noise
hc --skill                   # the current hc manual
hc <command> --help
```

Fleet flags that come up often: `--add-dir` (a second writable directory), `--model` / `--effort` (cheap workers beside one expensive reviewer), `--agent` / `--append-system-prompt` (a standing role, so you do not repeat it in each brief). Pass them to `spawn-fleet.py` with `--agent-arg=<flag>`, or after the harness name in `hc run`. Check the spelling of each flag in the help before you use it. Flags change between versions.
