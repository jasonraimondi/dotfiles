# Placement: flags, edge cases, teardown syntax

Read this when you choose a `spawn-fleet.py` placement, need a non-default flag, or write the teardown by hand.

## All spawn flags

- `--placement split|tab|workspace` — where the fleet appears (default `split`)
- `--direction right|down` — where each new pane goes (default `right`)
- `--per-tab 1|2` — sessions per tab or workspace (default 2)
- `--prefix <name>` — tab or workspace label prefix (default `fleet`)
- `--title <words>` — fleet mission, five words or fewer; labels tabs/workspaces `f1: <title>`, `f2: <title>`, … and beats `--prefix` when both are given
- `--harness pi|claude` — explicit override when coordinator detection is ambiguous
- `--peer-harness pi|claude` — harness the peers run in (default: the coordinator harness); `pi` from a Claude coordinator starts the coordinator's bridge before any layout, see `references/cross-harness.md`; `claude` from a Claude coordinator that owns a live bridge gives each peer bridge hooks through `--settings` and an `--append-system-prompt` telling it to act on framed pi-peer messages within its own permissions, and its row prints `uds:` and `pi:`; `claude` from a pi coordinator needs no coordinator bridge and gives each peer the same hooks and system prompt
- `--model <model>` — model for every session, interpreted by that harness
- `--agent-arg=<flag>` — repeatable native argument; use `=` for values beginning with `--`
- `--claude-arg=<flag>` — legacy Claude-only alias for native arguments
- `--timeout <seconds>` — shared agent-startup and messaging-readiness budget (default 120); layout creation uses separate bounded Herdr calls
- `--permission-mode <mode>` — Claude-only, defaults to `auto`; read `references/claude.md` first

Herdr splits `right` or `down` only. There is no `left` or `up`.

## Placement facts

- Every placement needs `HERDR_ENV=1`. The script exits outside Herdr.
- `split` splits **your** pane, found through `$HERDR_PANE_ID`. Its teardown closes the new panes only. It never closes your tab.
- Every pane is created with `--no-focus`, so the user's keystrokes stay in their own pane.
- Choose the direction by the shape of the pane you are splitting: a wide pane splits `right`, a narrow or tall pane splits `down`. Read the shape with `herdr pane layout --pane "$HERDR_PANE_ID"`.
- More than 3 sibling panes get cramped whichever way you split. Use `--placement tab`.
- The script passes `--cwd` to Herdr, so each session starts in its own directory with no `cd` typed into a shell.

## Teardown syntax per placement

Teardown is the default once the fleet's work is done (SKILL.md section 4); the user can ask to keep the fleet instead. These are the commands you run, and the commands you hand the user when they keep the fleet. Refresh identities before using saved PIDs and confirm process exit before closing layout.

The spawn script prints the exact teardown with the ids it created. When you must write it by hand:

```bash
kill <pid> <pid>                     # always first; pids from peer-addr.py

herdr pane close <pane_id>           # placement split, one per pane
herdr tab close <tab_id>             # placement tab
herdr workspace close <workspace_id> # placement workspace

python3 scripts/peer-addr.py --harness <pi|claude> # confirm gone; use the peer harness
```

A cross-harness fleet's block ends with an optional line. Stopping the bridge ends the coordinator's `pi:` reachability:

```bash
node <bridge.ts> stop --owner-pid <coordinator-pid>
```

Claude peers' bridges exit with their peers; killing the peer is enough.

Herdr ids (`w1`, `w1:t1`, `w1:p1`) are opaque and stable, and a closed id is never reused. An id you recorded at spawn still names the same thing at teardown, or nothing at all — it cannot drift onto another pane. Read ids from the JSON that created them, never from sidebar order.

A `split` fleet sits in the user's own tab, so `tab close` there closes the user's work too. Close only what you made.
