import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))

spec = importlib.util.spec_from_file_location("peer_addr", SCRIPTS / "peer-addr.py")
addr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(addr)

DEAD_PID = 2**31 - 2


class BridgeAddressTests(unittest.TestCase):
    def setUp(self):
        self.peer_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.peer_dir.cleanup)
        os.makedirs(os.path.join(self.peer_dir.name, "bridges"))
        self.output = io.StringIO()
        stack = contextlib.ExitStack()
        self.addCleanup(stack.close)
        stack.enter_context(contextlib.redirect_stdout(self.output))
        stack.enter_context(patch.dict(os.environ, {"PI_PEER_DIR": self.peer_dir.name, "CLAUDE_CODE_MESSAGING_SOCKET": "/me.sock"}))
        self.session = {"messagingSocketPath": "/me.sock", "sessionId": "s1", "pid": os.getpid(), "name": "boss"}
        stack.enter_context(patch.object(addr, "load_records", return_value=[self.session]))

    def write_bridge(self, bridge_pid, waiter="armed"):
        record = {"version": 1, "pid": bridge_pid, "ownerPid": os.getpid(), "address": "pi:bridge-1",
                  "spool": "/spool", "waiter": waiter}
        with open(os.path.join(self.peer_dir.name, "bridges", f"{os.getpid()}.json"), "w") as handle:
            json.dump(record, handle)

    def test_me_shows_pi_address_of_live_bridge(self):
        self.write_bridge(os.getpid())
        self.assertEqual(addr.me(as_json=True), 0)
        payload = json.loads(self.output.getvalue())
        self.assertEqual(payload["address"], "uds:/me.sock")
        self.assertEqual(payload["piAddress"], "pi:bridge-1")
        self.assertEqual(payload["bridge"]["waiter"], "armed")

    def test_me_text_prints_pi_address_on_second_line(self):
        self.write_bridge(os.getpid())
        addr.me()
        self.assertEqual(self.output.getvalue().splitlines()[:2], ["uds:/me.sock", "pi:bridge-1"])

    def test_me_ignores_dead_bridge(self):
        self.write_bridge(DEAD_PID)
        addr.me(as_json=True)
        payload = json.loads(self.output.getvalue())
        self.assertIsNone(payload["piAddress"])
        self.assertIsNone(payload["bridge"])

    def test_listing_shows_waiter_state_for_bridged_session(self):
        self.write_bridge(os.getpid(), waiter="expired")
        with patch.dict(os.environ, {"CLAUDE_CODE_MESSAGING_SOCKET": "/other.sock"}), \
                patch.object(addr, "socket_status", return_value="live"):
            addr.listing()
        self.assertIn("waiter expired", self.output.getvalue())

    def test_listing_marks_dead_bridge(self):
        self.write_bridge(DEAD_PID)
        with patch.dict(os.environ, {"CLAUDE_CODE_MESSAGING_SOCKET": "/other.sock"}), \
                patch.object(addr, "socket_status", return_value="live"):
            addr.listing()
        self.assertIn("bridge dead", self.output.getvalue())

    def test_listing_without_bridge_has_no_bridge_note(self):
        with patch.dict(os.environ, {"CLAUDE_CODE_MESSAGING_SOCKET": "/other.sock"}), \
                patch.object(addr, "socket_status", return_value="live"):
            addr.listing()
        self.assertNotIn("bridge", self.output.getvalue())
        self.assertNotIn("waiter", self.output.getvalue())


if __name__ == "__main__":
    unittest.main()
