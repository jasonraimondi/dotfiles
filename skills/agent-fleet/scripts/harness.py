"""Harness selection and pi-peer discovery; Claude keeps its native registry."""

import functools
import glob
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


# Where version managers keep Node builds, searched when PATH's node is too old for the bridge.
NODE_INSTALL_GLOBS = (
    "~/.proto/tools/node/*/bin/node",
    "~/.local/share/mise/installs/node/*/bin/node",
    "~/.nvm/versions/node/*/bin/node",
    "~/.volta/tools/image/node/*/bin/node",
    "~/.fnm/node-versions/*/installation/bin/node",
    "/opt/homebrew/opt/node*/bin/node",
    "/usr/local/opt/node*/bin/node",
)


def node_version(binary):
    """(execPath, (major, minor), 'x.y.z') of the Node a binary or shim runs, or None when it cannot say."""
    # Version-manager shims choose a Node per working directory, so keep the binary this one chose.
    probe = [binary, "-p", "process.execPath + '\\n' + process.versions.node"]
    try:
        result = subprocess.run(probe, capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return None
    lines = result.stdout.splitlines() if result.returncode == 0 else []
    match = re.fullmatch(r"(\d+)\.(\d+)\.\d+", lines[1]) if len(lines) == 2 else None
    if not match:
        return None
    return lines[0], (int(match[1]), int(match[2])), lines[1]


def installed_nodes():
    for pattern in NODE_INSTALL_GLOBS:
        for binary in glob.glob(os.path.expanduser(pattern)):
            if os.access(binary, os.X_OK):
                yield binary


@functools.cache
def bridge_node():
    """Absolute path of the Node that runs bridge.ts.

    PI_PEER_NODE wins when set. Otherwise PATH's node, and when that is missing
    or older than 22.18, the newest qualifying Node a version manager has
    installed. Raises RuntimeError when none qualifies.
    """
    minimum = ".".join(map(str, MIN_BRIDGE_NODE))
    needs = f"pi-peer bridge needs Node {minimum}+"
    pinned = os.environ.get("PI_PEER_NODE")
    candidate = shutil.which(pinned or "node")
    probed = node_version(os.path.abspath(candidate)) if candidate else None
    if probed and probed[1] >= MIN_BRIDGE_NODE:
        return probed[0]
    if pinned:
        reason = f"{candidate or pinned} is v{probed[2]}" if probed else f"{candidate or pinned} is not a usable Node"
        raise RuntimeError(f"{needs}; {reason}. Set PI_PEER_NODE to a newer node.")
    qualifying = [found for found in map(node_version, installed_nodes()) if found and found[1] >= MIN_BRIDGE_NODE]
    if qualifying:
        return max(qualifying, key=lambda found: tuple(int(part) for part in found[2].split(".")))[0]
    reason = f"PATH's node is v{probed[2]}" if probed else "no usable node on PATH"
    raise RuntimeError(f"{needs}; {reason} and no newer install was found. Set PI_PEER_NODE to a Node {minimum}+ binary.")


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
