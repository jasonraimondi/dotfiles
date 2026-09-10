# Manual Claude rigging, forks, and paths that the skill does not cover

Read this when `spawn-fleet.py` does not fit: unusual layouts, filming, forks, or a `claude`/`herdr` capability that the skill does not name.

## The Herdr object model

A **workspace** holds tabs. A tab holds panes. A pane holds one terminal, and Herdr recognizes a coding agent running inside it.

Ids are opaque and stable: `w1` for a workspace, `w1:t1` for a tab, `w1:p1` for a pane. A closed id is never reused, so an id you saved keeps naming the same thing for as long as that thing exists. Read every id out of the JSON that created it:

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
# → .result.pane.pane_id
```

`workspace create` returns `.result.workspace`, `.result.tab`, and `.result.root_pane`. `tab create` returns `.result.tab` and `.result.root_pane`.

One exception to id stability: `pane move` re-qualifies a pane id to its new workspace. Continue with `.result.move_result.pane.pane_id`.

## Where am I?

Herdr injects the caller's context into every managed pane:

```bash
printf '%s\n' "$HERDR_WORKSPACE_ID" "$HERDR_TAB_ID" "$HERDR_PANE_ID"
```

Build from those, or pass `--current`. A bare pane command with no target may hit the UI-focused pane, which can belong to the user or another client.

## A session beside your own pane

This is what `--placement split` does:

```bash
herdr pane split --current --direction right --cwd /tmp/lab/alpha --no-focus
# → .result.pane.pane_id, e.g. w1:p4

herdr pane rename w1:p4 alpha

herdr agent start alpha --kind claude --pane w1:p4 -- \
  --name alpha --permission-mode auto
```

`--no-focus` matters. Without it the UI jumps to the new pane, and the user's next keystrokes go to the peer.

`pane rename` gives the pane a short label — the session name. A Claude session keeps retitling its terminal with whatever it is doing, and the label is the one thing that survives that, so a labeled fleet stays readable. The spawn script does this for every pane it creates; do the same when rigging by hand.

`agent start` needs a pane already sitting at its shell prompt, and it returns only once Herdr sees Claude ready for input. It never creates or moves layout — split first, then start. The name binds the Herdr agent; `--name` after `--` binds the Claude session name that `SendMessage` and `peer-addr.py` resolve. Keep them identical.

Teardown stays off by default (SKILL.md section 4). Once the user asks: `herdr pane close <pane_id>`, one call per pane, after you kill the PIDs. Never `tab close` — that tab is the user's.

## A tab or a workspace of your own

```bash
herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd /tmp/lab --label fleet-1 --no-focus
# → .result.tab, .result.root_pane

herdr workspace create --cwd /tmp/lab --label fleet --no-focus
# → .result.workspace, .result.tab, .result.root_pane
```

Both hand you a live shell pane in `root_pane`. Start the agent there, then `pane split` off it for a second session in the same tab.

## Watch the panes

```bash
herdr agent read alpha --source recent-unwrapped --lines 120
herdr agent get alpha
```

Prefer Herdr's own waits to a poll loop. `herdr agent wait alpha --until blocked --timeout 120000` returns when the peer hits an approval or question UI; without `--until` it returns on the first settled `idle`, `done`, or `blocked`.

Read the lifecycle state rather than guessing from pixels. `working` means the turn is running. `blocked` means Herdr recognized an approval prompt — the stall that used to need a screen grep. `unknown` means an agent is present that Herdr cannot classify, and it never proves completion.

Claude Code runs on the terminal's alternate screen. Rows that scroll off it do not reach Herdr's scrollback, so raising `--lines` cannot recover a long reply that already scrolled. Recover it from the transcript instead — `scripts/peer-inbox.py`, in `troubleshooting.md`.

If you asked the peer to reply by `SendMessage`, end your turn instead of watching anything.

## Fork a session

`--fork-session` starts a peer from the history of an existing conversation, under a **new** session id. It runs in a shell pane, so strip the child marker:

```bash
herdr pane run <pane_id> "env -u CLAUDE_CODE_CHILD_SESSION claude --resume <sessionId> \
  --fork-session --name reviewer-a --permission-mode auto"
```

The fork starts with the full transcript and a fresh id. The original session continues, and you can address both. Without `--fork-session`, `--resume` uses the same id and the sessions collide.

Session id vs socket: the socket (`uds:...`) is the address of a running *process*. The session id is the address of a *conversation on disk*. Get your own id from `peer-addr.py --me`. Get another session's id from `sessionId` in `~/.claude/sessions/<pid>.json`.

To fork one session N ways is better than to write the same long brief N times.

## When you need something that this file does not cover

Read the help. Do not guess. Do not assume a thing is impossible:

```bash
COLUMNS=200 claude --help    # a pipe through head kills it with SIGPIPE;
claude agents --help         # narrow terminals wrap it into noise
herdr --help
herdr pane                   # a command group with no subcommand prints its help
```

Never run bare `herdr` for discovery — it launches or attaches the TUI. Never probe a mutating nested command by omitting arguments; `herdr workspace create` is valid with defaults and will execute.

Fleet flags that come up often: `--add-dir` (a second writable directory), `--model` / `--effort` (cheap workers beside one expensive reviewer), `--agent` / `--append-system-prompt` (a standing role, so you do not repeat it in each brief). Pass them to `spawn-fleet.py` with `--claude-arg`, or after `--` on `herdr agent start`. Check the spelling of each flag in the help before you use it. Flags change between versions.

Herdr's own worktree commands give each session its own git worktree when the fleet edits one repo: `herdr worktree create --branch <name>`. Create that topology only when the user asks for it.
