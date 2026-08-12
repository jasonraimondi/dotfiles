#!/usr/bin/env python3
"""Launch named Claude Code sessions in Herdr and verify their live sockets."""

import argparse
import json
import os
import re
import subprocess
import sys
import time

from peer_registry import live_records, normalized_name, record_identity, socket_live


# Herdr agent names and Claude session names come from the same argument, so a
# spec name must satisfy the stricter of the two.
HERDR_NAME = re.compile(r"^[a-z][a-z0-9_-]{0,31}$")
ADDR_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "peer-addr.py")


def herdr(*args):
    """Run a herdr command and return its `result` payload."""
    result = subprocess.run(["herdr", *args], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"herdr {' '.join(args)}\n  → {result.stderr.strip()}")
    try:
        return json.loads(result.stdout).get("result", {})
    except ValueError:
        raise RuntimeError(f"herdr {' '.join(args)}\n  → non-JSON: {result.stdout!r}")


def id_of(payload, kind):
    """Read an opaque id, whether herdr returned the object or the bare id."""
    value = payload.get(kind)
    if isinstance(value, dict):
        value = value.get(f"{kind.rsplit('_', 1)[-1]}_id") or value.get("id")
    if not isinstance(value, str):
        raise RuntimeError(f"no {kind} id in herdr result: {payload!r}")
    return value


def parse_specs(raw):
    specs = []
    fresh = []
    for item in raw:
        if ":" not in item:
            sys.exit(f"error: '{item}' is not NAME:DIR")
        name, _, directory = item.partition(":")
        name = name.strip()
        directory = os.path.abspath(os.path.expanduser(directory.strip()))
        if not HERDR_NAME.match(name):
            sys.exit(
                f"error: '{name}' is not a usable name. Herdr agent names start "
                "with a lowercase letter and hold up to 32 of [a-z0-9_-]."
            )
        if not os.path.isdir(directory):
            os.makedirs(directory, exist_ok=True)
            fresh.append(directory)
        specs.append((name, directory))
    names = [name for name, _ in specs]
    duplicates = {name for name in names if names.count(name) > 1}
    if duplicates:
        sys.exit(f"error: duplicate session names: {', '.join(sorted(duplicates))}")
    if fresh:
        print(
            f"note: created {len(fresh)} directory(s). Claude asks to trust a "
            "directory it has not seen, and a session waiting on that prompt "
            "never registers. Watch the panes: " + ", ".join(fresh),
            file=sys.stderr,
        )
    return specs


def new_matching_records(before, wanted):
    return [
        record
        for record in live_records()
        if record_identity(record) not in before and normalized_name(record) in wanted
    ]


def ready_by_name(records):
    ready = {}
    for record in records:
        if not socket_live(record.get("messagingSocketPath")):
            continue
        name = normalized_name(record)
        previous = ready.get(name)
        if previous is None or (record.get("startedAt") or 0) > (
            previous.get("startedAt") or 0
        ):
            ready[name] = record
    return ready


def print_cleanup(records, layout):
    pids = sorted(
        {record.get("pid") for record in records if isinstance(record.get("pid"), int)}
    )
    print("\nTeardown is off by default: hand this block to the user, and run it")
    print("only when they ask. Kill the processes before closing their panes:")
    if pids:
        print("  kill " + " ".join(str(pid) for pid in pids))
    else:
        print("  No launched PID registered yet; inspect the panes before closing them.")
    if layout["placement"] == "workspace":
        for workspace in layout["workspaces"]:
            print(f"  herdr workspace close {workspace}")
    elif layout["placement"] == "tab":
        for tab in layout["tabs"]:
            print(f"  herdr tab close {tab}")
    else:
        # Split placement lives in the caller's own tab. Close the new panes
        # only. Never close this tab or this workspace.
        for pane in layout["panes"]:
            print(f"  herdr pane close {pane}")
    print(f"  python3 {ADDR_SCRIPT}")


def label_panes(specs, panes):
    """Label each pane with its session name so the fleet reads at a glance."""
    for (name, _), pane in zip(specs, panes):
        try:
            herdr("pane", "rename", pane, name)
        except RuntimeError as error:
            print(f"note: could not label pane {pane}: {error}", file=sys.stderr)


def start_agent(name, pane, permission_mode, extra, timeout_ms):
    """Hand the pane to Herdr's agent supervisor and wait until Claude is up."""
    herdr(
        "agent",
        "start",
        name,
        "--kind",
        "claude",
        "--pane",
        pane,
        "--timeout",
        str(timeout_ms),
        "--",
        "--name",
        name,
        "--permission-mode",
        permission_mode,
        *extra,
    )


def split_pane(anchor, direction, directory):
    return id_of(
        herdr(
            "pane",
            "split",
            "--pane",
            anchor,
            "--direction",
            direction,
            "--cwd",
            directory,
            "--no-focus",
        ),
        "pane",
    )


def build_splits(specs, caller_pane, direction):
    """Put each session in a sibling pane of the caller's own pane."""
    if not caller_pane:
        sys.exit("error: no caller pane. Run this inside a Herdr-managed pane.")
    if len(specs) > 3:
        print(
            f"note: {len(specs)} sibling panes get cramped. "
            "Use --placement tab or --placement workspace.",
            file=sys.stderr,
        )
    panes = []
    anchor = caller_pane
    for _, directory in specs:
        pane = split_pane(anchor, direction, directory)
        panes.append(pane)
        anchor = pane  # chain, so the panes line up in spec order
    return {"placement": "split", "tabs": [], "workspaces": [], "panes": panes}


def build_groups(specs, placement, workspace, prefix, per_tab, direction, title):
    """Put each group of sessions in its own tab, or its own workspace."""
    tabs = []
    workspaces = []
    panes = []
    groups = [specs[index : index + per_tab] for index in range(0, len(specs), per_tab)]
    for group_index, group in enumerate(groups, 1):
        label = f"f{group_index}: {title}" if title else f"{prefix}-{group_index}"
        first_dir = group[0][1]
        if placement == "workspace":
            created = herdr(
                "workspace",
                "create",
                "--cwd",
                first_dir,
                "--label",
                label,
                "--no-focus",
            )
            workspaces.append(id_of(created, "workspace"))
        else:
            args = ["tab", "create", "--cwd", first_dir, "--label", label, "--no-focus"]
            if workspace:
                args += ["--workspace", workspace]
            created = herdr(*args)
            tabs.append(id_of(created, "tab"))
        anchor = id_of(created, "root_pane")
        panes.append(anchor)
        for _, directory in group[1:]:
            anchor = split_pane(anchor, direction, directory)
            panes.append(anchor)
    return {"placement": placement, "tabs": tabs, "workspaces": workspaces, "panes": panes}


def main():
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("specs", nargs="+", metavar="NAME:DIR")
    parser.add_argument(
        "--placement",
        choices=("split", "tab", "workspace"),
        default="split",
        help="split: sibling panes in this tab. tab: new tabs in this workspace. "
        "workspace: new workspaces (default: split)",
    )
    parser.add_argument(
        "--direction",
        choices=("right", "down"),
        default="right",
        help="direction of each new pane (default: right)",
    )
    parser.add_argument("--per-tab", type=int, default=2, choices=(1, 2))
    parser.add_argument("--prefix", default="fleet")
    parser.add_argument(
        "--title",
        help="short fleet mission, five words or fewer; tabs/workspaces are "
        "labeled 'f1: <title>', 'f2: <title>', … (default: <prefix>-N)",
    )
    parser.add_argument("--model")
    parser.add_argument("--claude-arg", action="append", default=[])
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--permission-mode", default="auto")
    args = parser.parse_args()

    if os.environ.get("HERDR_ENV") != "1":
        sys.exit("error: not inside a Herdr-managed pane. Start this fleet from Herdr.")

    specs = parse_specs(args.specs)
    before = {record_identity(record) for record in live_records()}
    wanted = {name for name, _ in specs}

    extra = list(args.claude_arg)
    if args.model:
        extra += ["--model", args.model]

    if args.placement == "split":
        layout = build_splits(specs, os.environ.get("HERDR_PANE_ID"), args.direction)
        print(f"tab {os.environ.get('HERDR_TAB_ID')} (this one)")
        print(f"panes {', '.join(layout['panes'])}")
    else:
        layout = build_groups(
            specs,
            args.placement,
            os.environ.get("HERDR_WORKSPACE_ID"),
            args.prefix,
            args.per_tab,
            args.direction,
            args.title,
        )
        created = layout["workspaces"] or layout["tabs"]
        print(f"{args.placement}s {', '.join(created)}")

    label_panes(specs, layout["panes"])

    started = time.time()
    # `agent start` returns once Claude is ready for input, which is earlier
    # than the messaging bind. Give the whole fleet one budget for both.
    agent_timeout_ms = max(4000, min(args.timeout, 300) * 1000)
    for (name, _), pane in zip(specs, layout["panes"]):
        start_agent(name, pane, args.permission_mode, extra, agent_timeout_ms)

    records = []
    ready = {}
    while time.time() - started < args.timeout:
        records = new_matching_records(before, wanted)
        ready = ready_by_name(records)
        if len(ready) == len(wanted):
            break
        time.sleep(2)

    elapsed = int(time.time() - started)
    records = new_matching_records(before, wanted)
    ready = ready_by_name(records)

    for name, _ in specs:
        if name in ready:
            record = ready[name]
            print(
                f"+ {name:<24} pid {record['pid']:<7} "
                f"uds:{record['messagingSocketPath']}"
            )
        else:
            print(f"- {name:<24} did not register a live socket in {args.timeout}s")

    missing = [name for name, _ in specs if name not in ready]
    if missing:
        print(
            f"\n{len(ready)}/{len(wanted)} ready after {elapsed}s. "
            "Read the pane with `herdr agent read <name>`. A session that waits "
            "for an answer never registers: a new directory asks 'Is this a "
            "project you created or one you trust?', and a non-auto mode asks "
            "'Do you want to proceed?'. A session that answers nothing and still "
            "has no socket inherited CLAUDE_CODE_CHILD_SESSION — relaunch that "
            "one pane with `herdr pane run <pane> \"env -u "
            'CLAUDE_CODE_CHILD_SESSION claude --name <name> --permission-mode auto"`.',
            file=sys.stderr,
        )
        print_cleanup(records, layout)
        return 1

    print(f"\n{len(ready)} ready in {elapsed}s.")
    print("Send with a uds: address above, or a freshly resolved ListAgents name/ref.")
    print_cleanup(records, layout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
