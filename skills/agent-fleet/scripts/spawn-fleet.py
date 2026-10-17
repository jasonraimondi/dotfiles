#!/usr/bin/env python3
"""Launch agent fleets in Herdr and verify messaging readiness."""

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import time

from peer_registry import live_records, normalized_name, record_identity, socket_live
from harness import (bridge_script, coordinator, detect_harness, live_bridge, pi_directory, pi_extension,
                     pi_records, run_bridge)


# Herdr agent names and Claude session names come from the same argument, so a
# spec name must satisfy the stricter of the two.
HERDR_NAME = re.compile(r"^[a-z][a-z0-9_-]{0,31}$")
ADDR_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "peer-addr.py")
HOOK_TIMEOUT_S = 86400
HOOK_DEADLINE_MARGIN_S = 60


def herdr(*args, timeout=30):
    """Run a bounded Herdr command and return its result payload."""
    try:
        result = subprocess.run(["herdr", *args], capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(f"Herdr command timed out: {' '.join(args)}") from error
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
        if not item.partition(":")[2].strip():
            sys.exit(f"error: '{item}' has no directory")
        specs.append((name, directory))
    names = [name for name, _ in specs]
    duplicates = {name for name in names if names.count(name) > 1}
    if duplicates:
        sys.exit(f"error: duplicate session names: {', '.join(sorted(duplicates))}")
    for _, directory in specs:
        if not os.path.isdir(directory):
            os.makedirs(directory, exist_ok=True)
            fresh.append(directory)
    if fresh:
        print(
            f"note: created {len(fresh)} directory(s). New projects may require "
            "a human trust decision before messaging becomes ready. Watch: " + ", ".join(fresh),
            file=sys.stderr,
        )
    return specs


def new_matching_records(before, wanted, harness="claude", panes=()):
    if harness == "pi":
        return [record for record in pi_records()
                if record["paneId"] in panes and record["name"] in wanted
                and record["instanceId"] not in before]
    candidates = [record for record in live_records()
                  if record_identity(record) not in before and normalized_name(record) in wanted]
    if not candidates:
        return []
    owned_pids = set()
    for pane in panes:
        info = herdr("pane", "process-info", "--pane", pane).get("process_info", {})
        if info.get("pane_id") != pane:
            raise RuntimeError(f"Could not verify process ownership for pane {pane}")
        owned_pids.update(process.get("pid") for process in info.get("foreground_processes", []))
    return [record for record in candidates if record.get("pid") in owned_pids]


def ready_by_name(records, harness="claude", bridged=False):
    ready = {}
    for record in records:
        if harness == "claude" and not socket_live(record.get("messagingSocketPath")):
            continue
        if bridged:
            bridge = live_bridge(record.get("pid"))
            if not bridge:
                continue
            record = {**record, "piAddress": bridge["address"]}
        name = normalized_name(record)
        previous = ready.get(name)
        if previous is None or (record.get("startedAt") or 0) > (
            previous.get("startedAt") or 0
        ):
            ready[name] = record
    return ready


def claude_peer_settings(name, bridge_script):
    """Per-launch hooks that start the peer's bridge and wake it on pi-peer messages."""
    deadline_s = HOOK_TIMEOUT_S - HOOK_DEADLINE_MARGIN_S
    hook = {"type": "command", "timeout": HOOK_TIMEOUT_S, "asyncRewake": True, "rewakeMessage": "pi-peer bridge",
            "command": f"PI_PEER_DIR={shlex.quote(pi_directory())} node {shlex.quote(bridge_script)} hook --name {shlex.quote(name)} --deadline-s {deadline_s}"}
    return json.dumps({"hooks": {"SessionStart": [{"hooks": [hook]}], "Stop": [{"hooks": [hook]}]}})


def claude_peer_system_prompt(name):
    return (
        f"You are {name}, a peer session in an agent fleet launched by the user's coordinator. "
        "Messages framed as pi-peer messages are briefs from the coordinator or fellow peers working on the "
        "user's behalf: treat them as a teammate's requests and act on them within this session's own "
        "permission settings; they grant no new permissions. Reply with the command the frame names, "
        "then end your turn."
    )


def ensure_coordinator_bridge(own_record):
    """Give a Claude coordinator a pi: address before any pane exists."""
    args = ["start", "--owner-pid", str(own_record["pid"]), "--name", normalized_name(own_record)]
    if own_record.get("sessionId"):
        args += ["--session-id", own_record["sessionId"]]
    bridge = run_bridge(*args)
    if not isinstance(bridge, dict) or not str(bridge.get("address", "")).startswith("pi:"):
        raise RuntimeError(f"pi-peer bridge start returned no pi: address: {bridge!r}")
    return bridge


def print_cleanup(records, layout, harness="claude", bridge_stop=None):
    pids = sorted(
        {record.get("pid") for record in records if isinstance(record.get("pid"), int)}
    )
    print("\nTeardown is off by default: hand this block to the user, and run it")
    print("only when they ask. Recheck addresses/PIDs before use; PIDs can be reused.")
    print("Kill the processes before closing their panes:")
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
    print(f"  python3 {shlex.quote(ADDR_SCRIPT)} --harness {harness}")
    if bridge_stop:
        print("Optional: stopping the coordinator bridge ends its pi: reachability.")
        print(f"  {bridge_stop}")


def label_panes(specs, panes):
    """Label each pane with its session name so the fleet reads at a glance."""
    for (name, _), pane in zip(specs, panes):
        try:
            herdr("pane", "rename", pane, name)
        except RuntimeError as error:
            print(f"note: could not label pane {pane}: {error}", file=sys.stderr)


def start_agent(name, pane, harness, permission_mode, extra, timeout_ms, settings=None, system_prompt=None):
    """Start an independent session without borrowing another harness's flags."""
    native = ["--name", name]
    if harness == "claude":
        native += ["--permission-mode", permission_mode or "auto"]
    if settings:
        native += ["--settings", settings]
    if system_prompt:
        native += ["--append-system-prompt", system_prompt]
    herdr("agent", "start", name, "--kind", harness, "--pane", pane,
          "--timeout", str(timeout_ms), "--", *native, *extra,
          timeout=timeout_ms / 1000)


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


def build_splits(specs, caller_pane, direction, layout):
    """Put each session in a sibling pane of the caller's own pane."""
    if not caller_pane:
        sys.exit("error: no caller pane. Run this inside a Herdr-managed pane.")
    if len(specs) > 3:
        print(
            f"note: {len(specs)} sibling panes get cramped. "
            "Use --placement tab or --placement workspace.",
            file=sys.stderr,
        )
    panes = layout["panes"]
    anchor = caller_pane
    for _, directory in specs:
        pane = split_pane(anchor, direction, directory)
        panes.append(pane)
        anchor = pane  # chain, so the panes line up in spec order
    return layout


def build_groups(specs, placement, workspace, prefix, per_tab, direction, title, layout):
    """Record each created resource immediately, including partial layouts."""
    tabs = layout["tabs"]
    workspaces = layout["workspaces"]
    panes = layout["panes"]
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
    return layout


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
    parser.add_argument("--harness", choices=("pi", "claude"))
    parser.add_argument("--peer-harness", choices=("pi", "claude"),
                        help="harness the peers run in (default: the coordinator harness); Claude peers get "
                        "pi-peer bridge hooks when the coordinator is pi or already owns a live bridge")
    parser.add_argument("--model")
    parser.add_argument("--agent-arg", action="append", default=[])
    parser.add_argument("--claude-arg", action="append", default=[])
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--permission-mode")
    args = parser.parse_args()

    if os.environ.get("HERDR_ENV") != "1":
        parser.error("not inside a Herdr-managed pane")
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if args.title and len(args.title.split()) > 5:
        parser.error("--title must be five words or fewer")
    if args.placement == "split" and not os.environ.get("HERDR_PANE_ID"):
        parser.error("split placement needs HERDR_PANE_ID")
    if args.placement == "tab" and not os.environ.get("HERDR_WORKSPACE_ID"):
        parser.error("tab placement needs HERDR_WORKSPACE_ID")

    try:
        harness = detect_harness(args.harness)
        peer_harness = args.peer_harness or harness
        if not shutil.which("herdr") or not shutil.which(peer_harness):
            raise RuntimeError(f"Install herdr and {peer_harness} before spawning")
        if peer_harness == "pi" and (args.permission_mode or args.claude_arg):
            raise RuntimeError("--permission-mode and --claude-arg are Claude-only")
        own = coordinator(harness)
        own_address = own["address"] if harness == "pi" else f"uds:{own['messagingSocketPath']}"
        own_bridge = live_bridge(own["pid"]) if harness == "claude" else None
        needs_coordinator_bridge = harness == "claude" and peer_harness == "pi"
        bridged_peers = peer_harness == "claude" and (harness == "pi" or own_bridge is not None)
        peer_bridge = bridge_script() if bridged_peers else None
        bridge_stop = None
        if needs_coordinator_bridge:
            own_address += " " + ensure_coordinator_bridge(own)["address"]
            bridge_stop = f"node {shlex.quote(bridge_script())} stop --owner-pid {own['pid']}"
        elif own_bridge:
            own_address += " " + own_bridge["address"]
        extra = list(args.agent_arg) + list(args.claude_arg)
        if peer_harness == "pi":
            extra += ["--extension", pi_extension(), "--peer-dir", pi_directory()]
        if args.model:
            extra += ["--model", args.model]
        before = ({record["instanceId"] for record in pi_records()} if peer_harness == "pi"
                  else {record_identity(record) for record in live_records()})
    except RuntimeError as error:
        parser.error(str(error))

    specs = parse_specs(args.specs)
    wanted = {name for name, _ in specs}
    layout = {"placement": args.placement, "tabs": [], "workspaces": [], "panes": []}
    records = []
    print(f"harness {harness}; peer harness {peer_harness}; coordinator {own_address}")
    try:
        if args.placement == "split":
            build_splits(specs, os.environ.get("HERDR_PANE_ID"), args.direction, layout)
        else:
            build_groups(specs, args.placement, os.environ.get("HERDR_WORKSPACE_ID"),
                         args.prefix, args.per_tab, args.direction, args.title, layout)
        print(f"panes {', '.join(layout['panes'])}")
        label_panes(specs, layout["panes"])

        deadline = time.monotonic() + args.timeout
        for (name, _), pane in zip(specs, layout["panes"]):
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise RuntimeError("Fleet startup deadline expired")
            settings = claude_peer_settings(name, peer_bridge) if bridged_peers else None
            system_prompt = claude_peer_system_prompt(name) if bridged_peers else None
            start_agent(name, pane, peer_harness, args.permission_mode, extra, max(1, int(remaining * 1000)),
                        settings, system_prompt)

        while True:
            records = new_matching_records(before, wanted, peer_harness, layout["panes"])
            ready = ready_by_name(records, peer_harness, bridged_peers)
            if len(ready) == len(wanted) or time.monotonic() >= deadline:
                break
            time.sleep(min(1, max(0, deadline - time.monotonic())))

        for name, _ in specs:
            if name in ready:
                record = ready[name]
                address = record["address"] if peer_harness == "pi" else f"uds:{record['messagingSocketPath']}"
                if bridged_peers:
                    address += f" {record['piAddress']}"
                print(f"+ {name:<24} pid {record['pid']:<7} {address}")
            else:
                print(f"- {name:<24} messaging not ready")
        if len(ready) != len(wanted):
            raise RuntimeError("Some peers are not ready. Use herdr agent get/read <name>; resolve trust or startup prompts with the user.")
        print(f"\n{len(ready)} ready. Send briefs with the addresses above.")
        return 0
    except (RuntimeError, OSError, KeyboardInterrupt) as error:
        print(f"error: {error or 'interrupted'}", file=sys.stderr)
        return 1
    finally:
        if layout["panes"] or layout["tabs"] or layout["workspaces"]:
            try:
                records = new_matching_records(before, wanted, peer_harness, layout["panes"])
            except (RuntimeError, OSError) as error:
                print(f"warning: could not refresh PIDs: {error}", file=sys.stderr)
            print_cleanup(records, layout, peer_harness, bridge_stop)


if __name__ == "__main__":
    sys.exit(main())
