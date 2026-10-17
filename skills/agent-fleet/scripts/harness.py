"""Harness selection and pi-peer discovery; Claude keeps its native registry."""

import functools
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

from peer_registry import pid_alive

MIN_BRIDGE_NODE = (22, 18)


def detect_harness(explicit=None):
    if explicit:
        return explicit
    pi = os.environ.get("PI_CODING_AGENT") == "true"
    claude = bool(os.environ.get("CLAUDE_CODE_MESSAGING_SOCKET") or os.environ.get("CLAUDE_CODE_CHILD_SESSION"))
    if pi == claude:
        raise RuntimeError("Cannot identify one coordinator harness; pass --harness pi or --harness claude explicitly.")
    return "pi" if pi else "claude"


def pi_directory():
    return os.path.abspath(os.environ.get("PI_PEER_DIR") or f"/tmp/pi-peer-{os.getuid()}")


@functools.cache
def bridge_node():
    """Absolute path of the Node that runs bridge.ts: PI_PEER_NODE, else PATH's node. Raises RuntimeError when missing or older than 22.18."""
    minimum = ".".join(map(str, MIN_BRIDGE_NODE))
    needs = f"pi-peer bridge needs Node {minimum}+"
    candidate = os.environ.get("PI_PEER_NODE") or "node"
    found = shutil.which(candidate)
    if not found:
        raise RuntimeError(f"{needs}; {candidate} not found. Set PI_PEER_NODE to a Node {minimum}+ binary.")
    found = os.path.abspath(found)
    # Version-manager shims choose a Node per working directory, so keep the binary this one chose.
    probe = [found, "-p", "process.execPath + '\\n' + process.versions.node"]
    try:
        result = subprocess.run(probe, capture_output=True, text=True, timeout=10)
        reason = result.stderr.strip() or f"exit {result.returncode}"
    except (OSError, subprocess.TimeoutExpired) as error:
        reason = str(error)
        result = None
    lines = result.stdout.splitlines() if result and result.returncode == 0 else []
    match = re.fullmatch(r"(\d+)\.(\d+)\.\d+", lines[1]) if len(lines) == 2 else None
    if not match:
        raise RuntimeError(f"{needs}; {found} could not report its version: {reason}. Set PI_PEER_NODE to a newer node.")
    path, version = lines
    if (int(match[1]), int(match[2])) < MIN_BRIDGE_NODE:
        raise RuntimeError(f"{needs}; {path} is v{version}. Set PI_PEER_NODE to a newer node.")
    return path


def bridge_for(pid):
    try:
        with open(os.path.join(pi_directory(), "bridges", f"{pid}.json")) as handle:
            bridge = json.load(handle)
    except (OSError, ValueError):
        return None
    return bridge if isinstance(bridge, dict) and bridge.get("ownerPid") == pid else None


def live_bridge(pid):
    bridge = bridge_for(pid)
    return bridge if bridge and pid_alive(bridge.get("pid")) else None


def run_bridge(*args, timeout=30):
    command = [bridge_node(), bridge_script(), *args]
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise RuntimeError(f"pi-peer bridge {' '.join(args)} failed: {error}") from error
    if result.returncode != 0:
        raise RuntimeError(f"pi-peer bridge {' '.join(args)} failed: {result.stderr.strip() or f'exit {result.returncode}'}")
    try:
        return json.loads(result.stdout)
    except ValueError as error:
        raise RuntimeError(f"pi-peer bridge {' '.join(args)} returned non-JSON: {result.stdout!r}") from error


def pi_records():
    records = run_bridge("list", "--json")
    if not isinstance(records, list):
        raise RuntimeError(f"pi-peer bridge list returned {type(records).__name__}, not a list")
    return records


def bridge_script():
    # An installed extension copy may predate bridge.ts; the repo copy is the one that reliably has it.
    candidates = [
        Path(__file__).resolve().parents[3] / "pi/extensions/pi-peer/bridge.ts",
        Path(os.environ.get("PI_CODING_AGENT_DIR", os.path.expanduser("~/.pi/agent"))) / "extensions/pi-peer/bridge.ts",
    ]
    for path in candidates:
        if path.is_file():
            return str(path)
    raise RuntimeError("pi-peer bridge.ts not found. Install this repo's pi/extensions/pi-peer directory first.")


def pi_extension():
    # pi auto-loads the installed copy; passing a second path registers peer_sessions twice.
    candidates = [
        Path(os.environ.get("PI_CODING_AGENT_DIR", os.path.expanduser("~/.pi/agent"))) / "extensions/pi-peer/index.ts",
        Path(__file__).resolve().parents[3] / "pi/extensions/pi-peer/index.ts",
    ]
    for path in candidates:
        if path.is_file():
            return str(path)
    raise RuntimeError("pi-peer extension not found. Install this repo's pi/extensions/pi-peer directory first.")


def coordinator(harness):
    if harness == "pi":
        matches = [record for record in pi_records() if record["sessionId"] == os.environ.get("PI_SESSION_ID")]
        if len(matches) != 1:
            raise RuntimeError("Coordinator is not uniquely registered with pi-peer. Load the extension, reload Pi, and confirm peer_sessions self before spawning.")
        return matches[0]
    from peer_registry import live_records
    own = os.environ.get("CLAUDE_CODE_MESSAGING_SOCKET")
    matches = [record for record in live_records(require_socket=True) if own and record.get("messagingSocketPath") == own]
    if len(matches) != 1:
        raise RuntimeError("Coordinator has no live Claude messaging socket. Confirm peer-addr.py --me before spawning.")
    return matches[0]
