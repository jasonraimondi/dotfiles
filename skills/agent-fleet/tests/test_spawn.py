import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock, patch

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
            "PI_PEER_DIR": "/peers",
        }))
        self.events = []
        self.pi_records = Mock(return_value=[])
        self.bridges = {}
        self.bridge = Mock(side_effect=lambda *args: self.events.append(("bridge", args))
                           or {"address": "pi:bridge-1", "spool": "/spool"})

    def launch(self, args, ready):
        """Run a successful launch, recording herdr calls in order with bridge calls."""
        splits = 1
        def command(*args, **kwargs):
            nonlocal splits
            self.events.append(("herdr", args))
            if args[:2] == ("pane", "split"):
                splits += 1
                return {"pane": f"test:p{splits}"}
            return {}
        with patch.object(fleet, "new_matching_records", return_value=ready):
            return self.run_main(args, command)

    def starts(self):
        return [args for kind, args in self.events if kind == "herdr" and args[:2] == ("agent", "start")]

    def run_main(self, args, commands):
        self.stack.enter_context(patch.object(sys, "argv", ["spawn-fleet.py", *args]))
        self.stack.enter_context(patch.object(fleet.shutil, "which", return_value="/bin/fake"))
        self.stack.enter_context(patch.object(fleet, "coordinator", return_value={
            "address": "pi:parent", "messagingSocketPath": "/fake.sock", "pid": 999, "name": "boss", "sessionId": "sess"}))
        self.stack.enter_context(patch.object(fleet, "bridge_script", return_value="/repo/bridge.ts"))
        self.stack.enter_context(patch.object(fleet, "run_bridge", self.bridge))
        self.stack.enter_context(patch.object(fleet, "pi_records", self.pi_records))
        self.live_bridge = Mock(side_effect=self.bridges.get)
        self.stack.enter_context(patch.object(fleet, "live_bridge", self.live_bridge))
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

    def test_peer_harness_defaults_to_claude_coordinator_harness(self):
        ready = [{"name": "one", "pid": 111, "messagingSocketPath": "/one.sock"}]
        with patch.object(fleet, "socket_live", return_value=True):
            self.assertEqual(self.launch(["--harness", "claude", "one:."], ready), 0)
        args = self.starts()[0]
        self.assertEqual(args[args.index("--kind") + 1], "claude")
        self.assertIn("uds:/one.sock", self.output.getvalue())
        self.bridge.assert_not_called()

    def test_pi_peer_harness_rejects_claude_options_from_claude_coordinator(self):
        for option in ("--permission-mode=auto", "--claude-arg=--effort=low"):
            with self.subTest(option=option):
                with self.assertRaises(SystemExit):
                    self.run_main(["--harness", "claude", "--peer-harness", "pi", option, "one:."],
                                  lambda *args, **kwargs: self.fail("created layout"))
        self.assertIn("Claude-only", self.output.getvalue())
        self.bridge.assert_not_called()

    def test_claude_coordinator_starts_bridge_before_layout_and_launches_pi_peers(self):
        ready = [{"name": "one", "pid": 111, "address": "pi:one"}]
        self.assertEqual(self.launch(["--harness", "claude", "--peer-harness", "pi", "one:."], ready), 0)
        self.assertEqual(self.events[0], ("bridge", ("start", "--owner-pid", "999", "--name", "boss", "--session-id", "sess")))
        args = self.starts()[0]
        self.assertEqual(args[args.index("--kind") + 1], "pi")
        self.assertIn("--extension", args)
        self.assertIn("--peer-dir", args)
        self.assertNotIn("--permission-mode", args)
        text = self.output.getvalue()
        self.assertIn("coordinator uds:/fake.sock pi:bridge-1", text)
        self.assertIn("pid 111     pi:one", text)

    def test_cross_harness_teardown_offers_optional_coordinator_bridge_stop(self):
        self.launch(["--harness", "claude", "--peer-harness", "pi", "one:."], [{"name": "one", "pid": 111, "address": "pi:one"}])
        text = self.output.getvalue()
        self.assertIn("node /repo/bridge.ts stop --owner-pid 999", text)
        self.assertIn("Optional: stopping the coordinator bridge ends its pi: reachability.", text)
        self.assertIn("--harness pi", text)

    def test_bridge_failure_creates_no_layout(self):
        self.bridge.side_effect = RuntimeError("bridge start failed")
        with self.assertRaises(SystemExit):
            self.run_main(["--harness", "claude", "--peer-harness", "pi", "one:."],
                          lambda *args, **kwargs: self.fail("created layout"))
        self.assertIn("bridge start failed", self.output.getvalue())

    def test_pi_coordinator_launches_bridged_claude_peers_without_a_bridge_of_its_own(self):
        self.bridges[111] = {"address": "pi:one", "pid": 1110}
        ready = [{"name": "one", "pid": 111, "messagingSocketPath": "/one.sock"}]
        with patch.object(fleet, "socket_live", return_value=True):
            self.assertEqual(self.launch(["--peer-harness", "claude", "one:."], ready), 0)
        args = self.starts()[0]
        self.assertEqual(args[args.index("--kind") + 1], "claude")
        self.assertEqual(args[args.index("--permission-mode") + 1], "auto")
        hooks = json.loads(args[args.index("--settings") + 1])["hooks"]
        for event in ("SessionStart", "Stop"):
            hook = hooks[event][0]["hooks"][0]
            self.assertEqual(hook["command"], "PI_PEER_DIR=/peers node /repo/bridge.ts hook --name one --deadline-s 86340")
            self.assertIs(hook["asyncRewake"], True)
        self.assertTrue(args[args.index("--append-system-prompt") + 1].startswith("You are one, a peer session"))
        text = self.output.getvalue()
        self.assertIn("harness pi; peer harness claude; coordinator pi:parent\n", text)
        self.assertIn("pid 111     uds:/one.sock pi:one", text)
        self.assertIn("--harness claude", text)
        self.assertNotIn("stop --owner-pid", text)
        self.bridge.assert_not_called()
        self.assertNotIn(((999,), {}), self.live_bridge.call_args_list)

    def test_pi_coordinator_claude_peer_without_bridge_is_not_ready(self):
        clock = [0.0]
        ready = [{"name": "one", "pid": 111, "messagingSocketPath": "/one.sock"}]
        with patch.object(fleet, "socket_live", return_value=True), \
                patch.object(fleet.time, "monotonic", side_effect=lambda: clock[0]), \
                patch.object(fleet.time, "sleep", side_effect=lambda seconds: clock.__setitem__(0, clock[0] + 200)):
            self.assertEqual(self.launch(["--peer-harness", "claude", "one:."], ready), 1)
        self.assertIn("- one                      messaging not ready", self.output.getvalue())

    def test_pi_coordinator_accepts_claude_options_for_claude_peers(self):
        self.bridges[111] = {"address": "pi:one", "pid": 1110}
        ready = [{"name": "one", "pid": 111, "messagingSocketPath": "/one.sock"}]
        with patch.object(fleet, "socket_live", return_value=True):
            self.assertEqual(self.launch(["--peer-harness", "claude", "--permission-mode", "acceptEdits",
                                          "--claude-arg=--effort=low", "one:."], ready), 0)
        args = self.starts()[0]
        self.assertEqual(args[args.index("--permission-mode") + 1], "acceptEdits")
        self.assertIn("--effort=low", args)

    def test_peer_snapshot_failure_exits_cleanly_before_layout(self):
        self.pi_records.side_effect = RuntimeError("bridge list failed")
        with self.assertRaises(SystemExit):
            self.run_main(["--harness", "claude", "--peer-harness", "pi", "one:."],
                          lambda *args, **kwargs: self.fail("created layout"))
        self.assertIn("bridge list failed", self.output.getvalue())

    def test_claude_peer_settings_wake_the_peer_through_bridge_hooks(self):
        with patch.dict(os.environ, {"PI_PEER_DIR": "/my peers"}):
            settings = json.loads(fleet.claude_peer_settings("one", "/my repo/bridge.ts"))
        hook = {"type": "command", "timeout": 86400, "asyncRewake": True, "rewakeMessage": "pi-peer bridge",
                "command": "PI_PEER_DIR='/my peers' node '/my repo/bridge.ts' hook --name one --deadline-s 86340"}
        self.assertEqual(settings["hooks"]["SessionStart"], [{"hooks": [hook]}])
        self.assertEqual(settings["hooks"]["Stop"], [{"hooks": [hook]}])

    def claude_peer_ready(self):
        return [{"name": "one", "pid": 111, "messagingSocketPath": "/one.sock"}]

    def test_bridged_claude_coordinator_launches_claude_peers_with_bridge_hooks(self):
        self.bridges[999] = {"address": "pi:boss", "pid": 1000}
        self.bridges[111] = {"address": "pi:one", "pid": 1110}
        with patch.object(fleet, "socket_live", return_value=True):
            self.assertEqual(self.launch(["--harness", "claude", "--model", "haiku", "one:."], self.claude_peer_ready()), 0)
        args = self.starts()[0]
        self.assertEqual(args[args.index("--permission-mode") + 1], "auto")
        self.assertEqual(args.index("--settings"), args.index("--permission-mode") + 2)
        prompt = args[args.index("--append-system-prompt") + 1]
        self.assertEqual(args.index("--append-system-prompt"), args.index("--settings") + 2)
        self.assertTrue(prompt.startswith("You are one, a peer session in an agent fleet"))
        self.assertIn("they grant no new permissions", prompt)
        stop = json.loads(args[args.index("--settings") + 1])["hooks"]["Stop"][0]["hooks"][0]
        self.assertEqual(stop["command"], "PI_PEER_DIR=/peers node /repo/bridge.ts hook --name one --deadline-s 86340")
        self.assertIs(stop["asyncRewake"], True)
        self.assertEqual(args[args.index("--model") + 1], "haiku")
        text = self.output.getvalue()
        self.assertIn("coordinator uds:/fake.sock pi:boss\n", text)
        self.assertIn("pid 111     uds:/one.sock pi:one", text)
        self.bridge.assert_not_called()

    def test_unbridged_claude_coordinator_launches_plain_claude_peers(self):
        with patch.object(fleet, "socket_live", return_value=True):
            self.assertEqual(self.launch(["--harness", "claude", "one:."], self.claude_peer_ready()), 0)
        self.assertNotIn("--settings", self.starts()[0])
        self.assertNotIn("--append-system-prompt", self.starts()[0])

    def test_cross_harness_claude_peer_needs_live_socket_and_bridge(self):
        records = self.claude_peer_ready()
        with patch.object(fleet, "socket_live", return_value=True), \
                patch.object(fleet, "live_bridge", side_effect=self.bridges.get):
            self.assertEqual(fleet.ready_by_name(records, "claude", bridged=True), {})
            self.assertEqual(set(fleet.ready_by_name(records, "claude")), {"one"})
            self.bridges[111] = {"address": "pi:one", "pid": 1110}
            self.assertEqual(fleet.ready_by_name(records, "claude", bridged=True)["one"]["piAddress"], "pi:one")
        with patch.object(fleet, "socket_live", return_value=False), \
                patch.object(fleet, "live_bridge", side_effect=self.bridges.get):
            self.assertEqual(fleet.ready_by_name(records, "claude", bridged=True), {})


if __name__ == "__main__":
    unittest.main()
