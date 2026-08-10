# Placement: flags, edge cases, teardown syntax

Read this when you choose a `spawn-fleet.py` placement, need a non-default flag, or write the teardown by hand.

## All spawn flags

- `--placement split|tab|workspace` — where the fleet appears (default `split`)
- `--direction right|down` — where each new pane goes (default `right`)
- `--per-tab 1|2` — sessions per tab or workspace (default 2)
- `--prefix <name>` — tab or workspace label prefix (default `fleet`)
- `--model <model>` — model for every session
- `--claude-arg <flag>` — repeatable escape hatch, passed to `claude` verbatim
- `--timeout <seconds>` — how long to wait for live sockets (default 120)
- `--permission-mode <mode>` — default `auto`; see SKILL.md before you change it

Herdr splits `right` or `down` only. There is no `left` or `up`.

## Placement facts

- Every placement needs `HERDR_ENV=1`. The script exits outside Herdr.
- `split` splits **your** pane, found through `$HERDR_PANE_ID`. Its teardown closes the new panes only. It never closes your tab.
- Every pane is created with `--no-focus`, so the user's keystrokes stay in their own pane.
- Choose the direction by the shape of the pane you are splitting: a wide pane splits `right`, a narrow or tall pane splits `down`. Read the shape with `herdr pane layout --pane "$HERDR_PANE_ID"`.
- More than 3 sibling panes get cramped whichever way you split. Use `--placement tab`.
- The script passes `--cwd` to Herdr, so each session starts in its own directory with no `cd` typed into a shell.

## Teardown syntax per placement

Teardown is off by default (SKILL.md section 4). These are the commands you hand the user, and the commands you run once the user asks.

The spawn script prints the exact teardown with the ids it created. When you must write it by hand:

```bash
kill <pid> <pid>                     # always first; pids from peer-addr.py

herdr pane close <pane_id>           # placement split, one per pane
herdr tab close <tab_id>             # placement tab
herdr workspace close <workspace_id> # placement workspace

python3 scripts/peer-addr.py         # confirm gone
```

Herdr ids (`w1`, `w1:t1`, `w1:p1`) are opaque and stable, and a closed id is never reused. An id you recorded at spawn still names the same thing at teardown, or nothing at all — it cannot drift onto another pane. Read ids from the JSON that created them, never from sidebar order.

A `split` fleet sits in the user's own tab, so `tab close` there closes the user's work too. Close only what you made.
