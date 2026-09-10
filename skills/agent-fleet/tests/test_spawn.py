import contextlib
import importlib.util
import io
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))
import harness

spec = importlib.util.spec_from_file_location("spawn_fleet", SCRIPTS / "spawn-fleet.py")
fleet = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fleet)


class FleetTests(unittest.TestCase):
    def setUp(self):
        self.output = io.StringIO()
        self.stack = contextlib.ExitStack()
        self.addCleanup(self.stack.close)
        self.stack.enter_context(contextlib.redirect_stdout(self.output))
        self.stack.enter_context(contextlib.redirect_stderr(self.output))
        self.stack.enter_context(patch.dict(os.environ, {
            "HERDR_ENV": "1", "HERDR_PANE_ID": "test:p1", "HERDR_WORKSPACE_ID": "test",
            "PI_CODING_AGENT": "true", "CLAUDE_CODE_MESSAGING_SOCKET": "", "CLAUDE_CODE_CHILD_SESSION": "",
        }))

    def run_main(self, args, commands):
        self.stack.enter_context(patch.object(sys, "argv", ["spawn-fleet.py", *args]))
        self.stack.enter_context(patch.object(fleet.shutil, "which", return_value="/bin/fake"))
        self.stack.enter_context(patch.object(fleet, "coordinator", return_value={"address": "pi:parent", "messagingSocketPath": "/fake.sock"}))
        self.stack.enter_context(patch.object(fleet, "pi_records", return_value=[]))
        self.stack.enter_context(patch.object(fleet, "live_records", return_value=[]))
        self.stack.enter_context(patch.object(fleet, "herdr", side_effect=commands))
        return fleet.main()

    def test_detects_harness_not_model(self):
        self.assertEqual(harness.detect_harness(), "pi")
        with patch.dict(os.environ, {"PI_CODING_AGENT": "", "CLAUDE_CODE_MESSAGING_SOCKET": "/s"}):
            self.assertEqual(harness.detect_harness(), "claude")
        with patch.dict(os.environ, {"CLAUDE_CODE_MESSAGING_SOCKET": "/s"}):
            with self.assertRaises(RuntimeError):
                harness.detect_harness()
            self.assertEqual(harness.detect_harness("pi"), "pi")

    def test_missing_coordinator_fails_before_creating_layout(self):
        with patch.object(sys, "argv", ["spawn-fleet.py", "one:."]), patch.object(fleet, "coordinator", side_effect=RuntimeError("not registered")), patch.object(fleet, "herdr") as command:
            with self.assertRaises(SystemExit):
                fleet.main()
            command.assert_not_called()
        self.assertIn("not registered", self.output.getvalue())

    def test_partial_layout_failure_prints_only_owned_pane(self):
        splits = 0
        def command(*args, **kwargs):
            nonlocal splits
            if args[:2] == ("pane", "split"):
                splits += 1
                if splits == 2:
                    raise RuntimeError("split failed")
                return {"pane": {"pane_id": "test:p2"}}
            raise AssertionError(args)
        self.assertEqual(self.run_main(["one:.", "two:."], command), 1)
        text = self.output.getvalue()
        self.assertIn("herdr pane close test:p2", text)
        self.assertNotIn("herdr pane close test:p1", text)
        self.assertNotIn("herdr tab close", text)

    def test_start_failure_prints_cleanup(self):
        def command(*args, **kwargs):
            if args[:2] == ("pane", "split"):
                return {"pane": "test:p2"}
            if args[:2] == ("agent", "start"):
                raise RuntimeError("startup failed")
            return {}
        self.assertEqual(self.run_main(["one:."], command), 1)
        self.assertIn("startup failed", self.output.getvalue())
        self.assertIn("herdr pane close test:p2", self.output.getvalue())

    def test_pi_launch_shares_deadline_and_uses_pi_flags(self):
        clock = [0.0]
        starts = []
        splits = 1
        def command(*args, **kwargs):
            nonlocal splits
            if args[:2] == ("pane", "split"):
                splits += 1
                return {"pane": f"test:p{splits}"}
            if args[:2] == ("agent", "start"):
                starts.append((args, kwargs))
                clock[0] += 70
            return {}
        ready = [{"name": "one", "pid": 111, "address": "pi:one"}, {"name": "two", "pid": 222, "address": "pi:two"}]
        with patch.object(fleet.time, "monotonic", side_effect=lambda: clock[0]), patch.object(fleet, "new_matching_records", return_value=ready):
            self.assertEqual(self.run_main(["--timeout", "120", "one:.", "two:."], command), 0)
        self.assertEqual([args[args.index("--timeout") + 1] for args, _ in starts], ["120000", "50000"])
        for args, kwargs in starts:
            self.assertEqual(args[args.index("--kind") + 1], "pi")
            self.assertIn("--extension", args)
            self.assertIn("--peer-dir", args)
            self.assertNotIn("--permission-mode", args)
        self.assertEqual(starts[1][1]["timeout"], 50)

    def test_claude_launch_keeps_native_permission_mode(self):
        calls = []
        with patch.object(fleet, "herdr", side_effect=lambda *args, **kwargs: calls.append(args)):
            fleet.start_agent("one", "test:p2", "claude", None, [], 1000)
        args = calls[0]
        self.assertEqual(args[args.index("--kind") + 1], "claude")
        self.assertEqual(args[args.index("--permission-mode") + 1], "auto")
        self.assertNotIn("--extension", args)

    def test_pi_rejects_claude_options_before_layout(self):
        for option in ("--permission-mode=auto", "--claude-arg=--effort=low"):
            with self.subTest(option=option):
                with self.assertRaises(SystemExit):
                    self.run_main([option, "one:."], lambda *args, **kwargs: self.fail("created layout"))
        self.assertIn("Claude-only", self.output.getvalue())

    def test_claude_readiness_checks_processes_in_owned_panes(self):
        records = [{"pid": 111, "name": "one"}, {"pid": 222, "name": "one"}]
        info = {"process_info": {"pane_id": "test:p2", "foreground_processes": [{"pid": 222}]}}
        with patch.object(fleet, "live_records", return_value=records), patch.object(fleet, "herdr", return_value=info):
            self.assertEqual(fleet.new_matching_records(set(), {"one"}, "claude", ["test:p2"]), [records[1]])

    def test_pi_readiness_ignores_same_named_sessions_in_other_panes(self):
        records = [
            {"instanceId": "old", "name": "one", "paneId": "test:p2"},
            {"instanceId": "foreign", "name": "one", "paneId": "other:p2"},
            {"instanceId": "owned", "name": "one", "paneId": "test:p2"},
        ]
        with patch.object(fleet, "pi_records", return_value=records):
            self.assertEqual(fleet.new_matching_records({"old"}, {"one"}, "pi", ["test:p2"]), [records[2]])


if __name__ == "__main__":
    unittest.main()
