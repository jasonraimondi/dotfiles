"""Harness selection and pi-peer discovery; Claude keeps its native registry."""

import glob
import json
import os
from pathlib import Path
import re
import socket
import stat

PI_ID = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")


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


def pi_ping(record, timeout=0.25):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(timeout)
        client.connect(record["socketPath"])
        client.sendall((json.dumps({"version": 1, "kind": "ping", "to": record["instanceId"]}) + "\n").encode())
        data = b""
        while b"\n" not in data:
            chunk = client.recv(4096)
            if not chunk:
                raise ValueError("Peer closed without a reply")
            data += chunk
            if len(data) > 65536:
                raise ValueError("Oversized peer response")
        result = json.loads(data.split(b"\n", 1)[0])
    live = result.get("result")
    if result.get("ok") is not True or not valid_pi_record(live):
        raise ValueError("Invalid pi-peer handshake")
    if any(live[key] != record[key] for key in ("instanceId", "sessionId", "pid", "socketPath")):
        raise ValueError("Peer identity changed")
    return live


def valid_pi_record(record):
    return (
        isinstance(record, dict) and record.get("version") == 1
        and all(isinstance(record.get(key), str) for key in (
            "instanceId", "sessionId", "name", "cwd", "paneId", "socketPath", "address"
        ))
        and PI_ID.fullmatch(record["instanceId"])
        and record["address"] == "pi:" + record["instanceId"]
        and type(record.get("pid")) is int and record["pid"] > 0
    )


def pi_records():
    root = pi_directory()
    try:
        mode = os.lstat(root)
    except FileNotFoundError:
        return []
    if not stat.S_ISDIR(mode.st_mode) or mode.st_uid != os.getuid() or mode.st_mode & 0o077:
        raise RuntimeError(f"Unsafe pi-peer directory (requires owner-only mode 0700): {root}")
    records = []
    for path in sorted(glob.glob(os.path.join(root, "*.json"))):
        try:
            mode = os.lstat(path)
            if not stat.S_ISREG(mode.st_mode) or mode.st_uid != os.getuid() or mode.st_mode & 0o077 or mode.st_size > 65536:
                continue
            with open(path) as handle:
                record = json.load(handle)
            if not valid_pi_record(record):
                continue
            if Path(path).stem != record["instanceId"] or record["socketPath"] != os.path.join(root, record["instanceId"] + ".sock"):
                continue
            records.append(pi_ping(record))
        except (OSError, ValueError, KeyError, TypeError, AttributeError):
            continue
    return records


def pi_extension():
    candidates = [
        Path(__file__).resolve().parents[3] / "pi/extensions/pi-peer/index.ts",
        Path(os.environ.get("PI_CODING_AGENT_DIR", os.path.expanduser("~/.pi/agent"))) / "extensions/pi-peer/index.ts",
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
