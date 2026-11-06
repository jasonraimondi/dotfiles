#!/usr/bin/env python3
"""Launch agent fleets in herdr-core terminals and verify messaging readiness."""

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
from harness import (bridge_node, bridge_script, coordinator, detect_harness, live_bridge, pi_directory, pi_extension,
                     pi_records, run_bridge)


# hc terminal names and Claude session names come from the same argument, so a
# spec name must satisfy the stricter of the two.
PEER_NAME = re.compile(r"^[a-z][a-z0-9_-]{0,31}$")
ADDR_SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "peer-addr.py")
HOOK_TIMEOUT_S = 86400
HOOK_DEADLINE_MARGIN_S = 60
# hc gives explicit commands the bare login-session environment; an interactive
# login shell restores the PATH (mise shims, pnpm) a peer's tools expect.
EXEC_ARGS = 'exec "$0" "$@"'


def hc(*args, timeout=30):
    """Run a bounded hc command and return its JSON payload."""
    try:
        result = subprocess.run(["hc", *args], capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(f"hc command timed out: {' '.join(args)}") from error
    if result.returncode != 0:
        raise RuntimeError(f"hc {' '.join(args)}\n  → {(result.stderr or result.stdout).strip()}")
    try:
        return json.loads(result.stdout)
    except ValueError:
        raise RuntimeError(f"hc {' '.join(args)}\n  → non-JSON: {result.stdout!r}")


def parse_specs(raw):
    specs = []
    fresh = []
    for item in raw:
        if ":" not in item:
            sys.exit(f"error: '{item}' is not NAME:DIR[@MODEL]")
        name, _, rest = item.partition(":")
        name = name.strip()
        directory, at, model = rest.rpartition("@") if "@" in rest else (rest, "", "")
        model = model.strip()
        if not PEER_NAME.match(name):
            sys.exit(
                f"error: '{name}' is not a usable name. Peer names start "
                "with a lowercase letter and hold up to 32 of [a-z0-9_-]."
            )
        if not directory.strip():
            sys.exit(f"error: '{item}' has no directory")
        if at and not model:
            sys.exit(f"error: '{item}' has no model after @")
        directory = os.path.abspath(os.path.expanduser(directory.strip()))
        specs.append((name, directory, model))
    names = [name for name, _, _ in specs]
    duplicates = {name for name in names if names.count(name) > 1}
    if duplicates:
        sys.exit(f"error: duplicate session names: {', '.join(sorted(duplicates))}")
    for _, directory, _ in specs:
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


def new_matching_records(before, wanted, harness="claude", terminals=()):
    if harness == "pi":
        return [record for record in pi_records()
                if record["terminalId"] in terminals and record["name"] in wanted
                and record["instanceId"] not in before]
    candidates = [record for record in live_records()
                  if record_identity(record) not in before and normalized_name(record) in wanted]
    if not candidates:
        return []
    owned_pids = {(hc("get", terminal).get("foreground") or {}).get("pid") for terminal in terminals}
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
            "command": f"PI_PEER_DIR={shlex.quote(pi_directory())} {shlex.quote(bridge_node())} {shlex.quote(bridge_script)} hook --name {shlex.quote(name)} --deadline-s {deadline_s}"}
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
    """Give a Claude coordinator a pi: address before any peer terminal exists."""
    args = ["start", "--owner-pid", str(own_record["pid"]), "--name", normalized_name(own_record)]
    if own_record.get("sessionId"):
        args += ["--session-id", own_record["sessionId"]]
    bridge = run_bridge(*args)
    if not isinstance(bridge, dict) or not str(bridge.get("address", "")).startswith("pi:"):
        raise RuntimeError(f"pi-peer bridge start returned no pi: address: {bridge!r}")
    return bridge


def print_cleanup(terminals, harness="claude", bridge_stop=None):
    print("\nTear the fleet down when its work is done, unless the user asked to keep it.")
    for terminal in terminals:
        print(f"  hc kill {terminal} && hc rm {terminal}")
    print(f"  python3 {shlex.quote(ADDR_SCRIPT)} --harness {harness}")
    if bridge_stop:
        print("Optional: stopping the coordinator bridge ends its pi: reachability.")
        print(f"  {bridge_stop}")


def window_labels():
    """Open each peer as a tab in the coordinator's space; a coordinator outside the window gets hidden peers."""
    space = hc("get", os.environ["HC_TERMINAL_ID"]).get("labels", {}).get("herdr.space")
    if not space:
        print("note: this terminal is not in the Herdr window, so peers start hidden. Show one with herdr-app.",
              file=sys.stderr)
        return []
    return ["--label", f"herdr.space={space}"]


def start_agent(name, directory, harness, permission_mode, extra, labels, settings=None, system_prompt=None, model=None):
    """Start an independent session without borrowing another harness's flags; return its terminal address."""
    native = ["--name", name]
    if harness == "claude":
        native += ["--permission-mode", permission_mode or "auto"]
    if settings:
        native += ["--settings", settings]
    if system_prompt:
        native += ["--append-system-prompt", system_prompt]
    if model:
        native += ["--model", model]
    launched = hc("run", "--bg", "--json", "--name", name, "--cwd", directory, *labels,
                  "--", os.environ.get("SHELL") or "/bin/zsh", "-ilc", EXEC_ARGS, harness, *native, *extra)
    return launched["address"]


def main():
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("specs", nargs="+", metavar="NAME:DIR[@MODEL]")
    parser.add_argument("--harness", choices=("pi", "claude"))
    parser.add_argument("--peer-harness", choices=("pi", "claude"),
                        help="harness the peers run in (default: the coordinator harness); Claude peers get "
                        "pi-peer bridge hooks when the coordinator is pi or already owns a live bridge")
    parser.add_argument("--model", help="model for every peer without its own NAME:DIR@MODEL, interpreted by the peer harness")
    parser.add_argument("--agent-arg", action="append", default=[])
    parser.add_argument("--claude-arg", action="append", default=[])
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--permission-mode")
    args = parser.parse_args()

    if not os.environ.get("HC_TERMINAL_ID"):
        parser.error("not inside a herdr-core terminal: HC_TERMINAL_ID is unset")
    if args.timeout <= 0:
        parser.error("--timeout must be positive")

    try:
        harness = detect_harness(args.harness)
        peer_harness = args.peer_harness or harness
        if not shutil.which("hc") or not shutil.which(peer_harness):
            raise RuntimeError(f"Install herdr-core (hc) and {peer_harness} before spawning")
        if peer_harness == "pi" and (args.permission_mode or args.claude_arg):
            raise RuntimeError("--permission-mode and --claude-arg are Claude-only")
        own = coordinator(harness)
        own_address = own["address"] if harness == "pi" else f"uds:{own['messagingSocketPath']}"
        own_bridge = live_bridge(own["pid"]) if harness == "claude" else None
        needs_coordinator_bridge = harness == "claude" and peer_harness == "pi"
        bridged_peers = peer_harness == "claude" and (harness == "pi" or own_bridge is not None)
        node = bridge_node() if needs_coordinator_bridge or bridged_peers else None
        peer_bridge = bridge_script() if bridged_peers else None
        bridge_stop = None
        if needs_coordinator_bridge:
            own_address += " " + ensure_coordinator_bridge(own)["address"]
            bridge_stop = f"{shlex.quote(node)} {shlex.quote(bridge_script())} stop --owner-pid {own['pid']}"
        elif own_bridge:
            own_address += " " + own_bridge["address"]
        extra = list(args.agent_arg) + list(args.claude_arg)
        if peer_harness == "pi":
            extra += ["--extension", pi_extension(), "--peer-dir", pi_directory()]
        before = ({record["instanceId"] for record in pi_records()} if peer_harness == "pi"
                  else {record_identity(record) for record in live_records()})
    except RuntimeError as error:
        parser.error(str(error))

    specs = parse_specs(args.specs)
    wanted = {name for name, _, _ in specs}
    terminals = []
    records = []
    print(f"harness {harness}; peer harness {peer_harness}; coordinator {own_address}")
    if node:
        print(f"bridge node {node}")
    try:
        labels = window_labels()
        deadline = time.monotonic() + args.timeout
        for name, directory, model in specs:
            settings = claude_peer_settings(name, peer_bridge) if bridged_peers else None
            system_prompt = claude_peer_system_prompt(name) if bridged_peers else None
            terminals.append(start_agent(name, directory, peer_harness, args.permission_mode, extra, labels,
                                         settings, system_prompt, model or args.model))
        print(f"terminals {', '.join(terminals)}")

        while True:
            records = new_matching_records(before, wanted, peer_harness, terminals)
            ready = ready_by_name(records, peer_harness, bridged_peers)
            if len(ready) == len(wanted) or time.monotonic() >= deadline:
                break
            time.sleep(min(1, max(0, deadline - time.monotonic())))

        for name, _, _ in specs:
            if name in ready:
                record = ready[name]
                address = record["address"] if peer_harness == "pi" else f"uds:{record['messagingSocketPath']}"
                if bridged_peers:
                    address += f" {record['piAddress']}"
                print(f"+ {name:<24} pid {record['pid']:<7} {address}")
            else:
                print(f"- {name:<24} messaging not ready")
        if len(ready) != len(wanted):
            raise RuntimeError("Some peers are not ready. Use hc get/read <name>; resolve trust or startup prompts with the user.")
        print(f"\n{len(ready)} ready. Send briefs with the addresses above.")
        return 0
    except (RuntimeError, OSError, KeyboardInterrupt) as error:
        print(f"error: {error or 'interrupted'}", file=sys.stderr)
        return 1
    finally:
        if terminals:
            print_cleanup(terminals, peer_harness, bridge_stop)


if __name__ == "__main__":
    sys.exit(main())
