import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))
import harness

spec = importlib.util.spec_from_file_location("spawn_fleet", SCRIPTS / "spawn-fleet.py")
fleet = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fleet)


COORDINATOR = {"address": "t1", "labels": {"herdr.space": "sp1", "herdr.tab": "tb1"}}


def argv_after_dashes(args):
    """The peer's own argv, after the login-shell wrapper."""
    return list(args[args.index("--") + 4:])


class FleetTests(unittest.TestCase):
    def setUp(self):
        self.output = io.StringIO()
        self.stack = contextlib.ExitStack()
        self.addCleanup(self.stack.close)
        self.stack.enter_context(contextlib.redirect_stdout(self.output))
        self.stack.enter_context(contextlib.redirect_stderr(self.output))
        self.peer_dir = self.stack.enter_context(tempfile.TemporaryDirectory())
        self.stack.enter_context(patch.dict(os.environ, {
            "HC_TERMINAL_ID": "t1",
            "PI_CODING_AGENT": "true", "CLAUDE_CODE_MESSAGING_SOCKET": "", "CLAUDE_CODE_CHILD_SESSION": "",
            "PI_PEER_DIR": self.peer_dir,
        }))
        self.bridge_script = "/repo/bridge.ts"
        self.events = []
        self.pi_records = Mock(return_value=[])
        self.bridges = {}
        self.bridge = Mock(side_effect=lambda *args: self.events.append(("bridge", args))
                           or {"address": "pi:bridge-1", "spool": "/spool"})
        self.node = self.stack.enter_context(patch.object(fleet, "bridge_node", return_value="/opt/node/bin/node"))

    def command(self, coordinator=COORDINATOR, fail_run=None):
        """Fake hc: records calls in order with bridge calls and hands out t2, t3, … to each run."""
        runs = 1
        def command(*args, **kwargs):
            nonlocal runs
            self.events.append(("hc", args))
            if args[0] == "get":
                return coordinator
            if args[0] == "run":
                runs += 1
                if runs == fail_run:
                    raise RuntimeError("startup failed")
                return {"address": f"t{runs}"}
            raise AssertionError(args)
        return command

    def launch(self, args, ready, coordinator=COORDINATOR):
        with patch.object(fleet, "new_matching_records", return_value=ready):
            return self.run_main(args, self.command(coordinator))

    def starts(self):
        return [args for kind, args in self.events if kind == "hc" and args[0] == "run"]

    def run_main(self, args, commands):
        self.stack.enter_context(patch.object(sys, "argv", ["spawn-fleet.py", *args]))
        self.stack.enter_context(patch.object(fleet.shutil, "which", return_value="/bin/fake"))
        self.stack.enter_context(patch.object(fleet, "coordinator", return_value={
            "address": "pi:parent", "messagingSocketPath": "/fake.sock", "pid": 999, "name": "boss", "sessionId": "sess"}))
        self.stack.enter_context(patch.object(fleet, "bridge_script", return_value=self.bridge_script))
        self.stack.enter_context(patch.object(fleet, "run_bridge", self.bridge))
        self.stack.enter_context(patch.object(fleet, "pi_records", self.pi_records))
        self.live_bridge = Mock(side_effect=self.bridges.get)
        self.stack.enter_context(patch.object(fleet, "live_bridge", self.live_bridge))
        self.stack.enter_context(patch.object(fleet, "live_records", return_value=[]))
        self.stack.enter_context(patch.object(fleet, "hc", side_effect=commands))
        return fleet.main()

    def test_detects_harness_not_model(self):
        self.assertEqual(harness.detect_harness(), "pi")
        with patch.dict(os.environ, {"PI_CODING_AGENT": "", "CLAUDE_CODE_MESSAGING_SOCKET": "/s"}):
            self.assertEqual(harness.detect_harness(), "claude")
        with patch.dict(os.environ, {"CLAUDE_CODE_MESSAGING_SOCKET": "/s"}):
            with self.assertRaises(RuntimeError):
                harness.detect_harness()
            self.assertEqual(harness.detect_harness("pi"), "pi")

    def test_spawning_needs_a_herdr_core_terminal(self):
        with patch.dict(os.environ, {"HC_TERMINAL_ID": ""}):
            with self.assertRaises(SystemExit):
                self.run_main(["one:."], lambda *args, **kwargs: self.fail("started a terminal"))
        self.assertIn("HC_TERMINAL_ID", self.output.getvalue())

    def test_missing_coordinator_fails_before_creating_layout(self):
        with patch.object(sys, "argv", ["spawn-fleet.py", "one:."]), patch.object(fleet, "coordinator", side_effect=RuntimeError("not registered")), patch.object(fleet, "hc") as command:
            with self.assertRaises(SystemExit):
                fleet.main()
            command.assert_not_called()
        self.assertIn("not registered", self.output.getvalue())

    def test_peers_open_as_tabs_in_the_coordinators_space(self):
        ready = [{"name": "one", "pid": 111, "address": "pi:one"}, {"name": "two", "pid": 222, "address": "pi:two"}]
        self.assertEqual(self.launch([f"one:{self.peer_dir}", "two:."], ready), 0)
        first, second = self.starts()
        self.assertEqual(first[:first.index("--")], ("run", "--bg", "--json", "--name", "one-tmp", "--cwd", self.peer_dir,
                                                     "--label", "herdr.space=sp1"))
        self.assertEqual(second[second.index("--name") + 1], "two-tmp")
        self.assertIn("terminals t2, t3", self.output.getvalue())

    def test_peers_start_through_an_interactive_login_shell(self):
        ready = [{"name": "one", "pid": 111, "address": "pi:one"}]
        with patch.dict(os.environ, {"SHELL": "/bin/zsh"}):
            self.assertEqual(self.launch(["one:."], ready), 0)
        args = self.starts()[0]
        self.assertEqual(list(args[args.index("--") + 1:][:5]), ["/bin/zsh", "-ilc", 'exec "$0" "$@"', "pi", "--name"])

    def test_coordinator_outside_the_window_starts_hidden_peers(self):
        ready = [{"name": "one", "pid": 111, "address": "pi:one"}]
        self.assertEqual(self.launch(["one:."], ready, coordinator={"address": "t1", "labels": {}}), 0)
        self.assertNotIn("--label", self.starts()[0])
        self.assertIn("hidden", self.output.getvalue())

    def test_teardown_kills_and_removes_only_started_terminals(self):
        with patch.object(fleet, "new_matching_records", return_value=[]):
            self.assertEqual(self.run_main(["one:.", "two:.", "three:."], self.command(fail_run=3)), 1)
        text = self.output.getvalue()
        self.assertIn("startup failed", text)
        self.assertIn("hc kill t2 && hc rm t2", text)
        self.assertNotIn("hc kill t1", text)
        self.assertNotIn("t3", text.split("startup failed", 1)[1])

    def test_pi_launch_uses_pi_flags(self):
        ready = [{"name": "one", "pid": 111, "address": "pi:one"}]
        self.assertEqual(self.launch(["one:."], ready), 0)
        argv = argv_after_dashes(self.starts()[0])
        self.assertEqual(argv[:3], ["pi", "--name", "one"])
        self.assertIn("--extension", argv)
        self.assertIn("--peer-dir", argv)
        self.assertNotIn("--permission-mode", argv)

    def test_claude_launch_keeps_native_permission_mode(self):
        calls = []
        with patch.object(fleet, "hc", side_effect=lambda *args, **kwargs: calls.append(args) or {"address": "t2"}):
            self.assertEqual(fleet.start_agent("one", "/w", "claude", None, [], []), "t2")
        argv = argv_after_dashes(calls[0])
        self.assertEqual(argv[:3], ["claude", "--name", "one"])
        self.assertEqual(argv[argv.index("--permission-mode") + 1], "auto")
        self.assertNotIn("--extension", argv)

    def test_pi_rejects_claude_options_before_layout(self):
        for option in ("--permission-mode=auto", "--claude-arg=--effort=low"):
            with self.subTest(option=option):
                with self.assertRaises(SystemExit):
                    self.run_main([option, "one:."], lambda *args, **kwargs: self.fail("created layout"))
        self.assertIn("Claude-only", self.output.getvalue())

    def test_claude_readiness_checks_processes_in_owned_terminals(self):
        records = [{"pid": 111, "name": "one"}, {"pid": 222, "name": "one"}]
        terminal = {"address": "t2", "foreground": {"pid": 222}}
        with patch.object(fleet, "live_records", return_value=records), patch.object(fleet, "hc", return_value=terminal):
            self.assertEqual(fleet.new_matching_records(set(), {"one"}, "claude", ["t2"]), [records[1]])

    def test_claude_readiness_skips_a_terminal_whose_program_ended(self):
        records = [{"pid": 222, "name": "one"}]
        with patch.object(fleet, "live_records", return_value=records), \
                patch.object(fleet, "hc", return_value={"address": "t2", "foreground": None}):
            self.assertEqual(fleet.new_matching_records(set(), {"one"}, "claude", ["t2"]), [])

    def test_pi_readiness_ignores_same_named_sessions_in_other_terminals(self):
        records = [
            {"instanceId": "old", "name": "one", "terminalId": "t2"},
            {"instanceId": "foreign", "name": "one", "terminalId": "t9"},
            {"instanceId": "owned", "name": "one", "terminalId": "t2"},
        ]
        with patch.object(fleet, "pi_records", return_value=records):
            self.assertEqual(fleet.new_matching_records({"old"}, {"one"}, "pi", ["t2"]), [records[2]])

    def test_peer_harness_defaults_to_claude_coordinator_harness(self):
        ready = [{"name": "one", "pid": 111, "messagingSocketPath": "/one.sock"}]
        with patch.object(fleet, "socket_live", return_value=True):
            self.assertEqual(self.launch(["--harness", "claude", "one:."], ready), 0)
        args = argv_after_dashes(self.starts()[0])
        self.assertEqual(args[0], "claude")
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
        args = argv_after_dashes(self.starts()[0])
        self.assertEqual(args[0], "pi")
        self.assertIn("--extension", args)
        self.assertIn("--peer-dir", args)
        self.assertNotIn("--permission-mode", args)
        text = self.output.getvalue()
        self.assertIn("coordinator uds:/fake.sock pi:bridge-1\nbridge node /opt/node/bin/node\n", text)
        self.assertIn("pid 111     pi:one", text)

    def test_cross_harness_teardown_offers_optional_coordinator_bridge_stop(self):
        self.node.return_value = "/my node/bin/node"
        self.launch(["--harness", "claude", "--peer-harness", "pi", "one:."], [{"name": "one", "pid": 111, "address": "pi:one"}])
        text = self.output.getvalue()
        self.assertIn("'/my node/bin/node' /repo/bridge.ts stop --owner-pid 999", text)
        self.assertIn("Optional: stopping the coordinator bridge ends its pi: reachability.", text)
        self.assertIn("--harness pi", text)

    def test_bridge_failure_creates_no_layout(self):
        self.bridge.side_effect = RuntimeError("bridge start failed")
        with self.assertRaises(SystemExit):
            self.run_main(["--harness", "claude", "--peer-harness", "pi", "one:."],
                          lambda *args, **kwargs: self.fail("created layout"))
        self.assertIn("bridge start failed", self.output.getvalue())

    def test_old_bridge_node_fails_before_bridge_or_layout(self):
        self.node.side_effect = RuntimeError("pi-peer bridge needs Node 22.18+; /old/node is v22.15.0.")
        with self.assertRaises(SystemExit):
            self.run_main(["--harness", "claude", "--peer-harness", "pi", "one:."],
                          lambda *args, **kwargs: self.fail("created layout"))
        self.assertIn("/old/node is v22.15.0", self.output.getvalue())
        self.bridge.assert_not_called()

    def test_old_bridge_node_fails_before_layout_for_bridged_claude_peers(self):
        self.node.side_effect = RuntimeError("pi-peer bridge needs Node 22.18+; /old/node is v22.15.0.")
        with self.assertRaises(SystemExit):
            self.run_main(["--peer-harness", "claude", "one:."], lambda *args, **kwargs: self.fail("created layout"))
        self.assertIn("/old/node is v22.15.0", self.output.getvalue())

    def test_pi_coordinator_launches_bridged_claude_peers_without_a_bridge_of_its_own(self):
        self.bridges[111] = {"address": "pi:one", "pid": 1110}
        ready = [{"name": "one", "pid": 111, "messagingSocketPath": "/one.sock"}]
        with patch.object(fleet, "socket_live", return_value=True):
            self.assertEqual(self.launch(["--peer-harness", "claude", "one:."], ready), 0)
        args = argv_after_dashes(self.starts()[0])
        self.assertEqual(args[0], "claude")
        self.assertEqual(args[args.index("--permission-mode") + 1], "auto")
        hooks = json.loads(args[args.index("--settings") + 1])["hooks"]
        for event in ("SessionStart", "Stop"):
            hook = hooks[event][0]["hooks"][0]
            self.assertEqual(hook["command"], f"PI_PEER_DIR={self.peer_dir} /opt/node/bin/node /repo/bridge.ts hook --name one --deadline-s 86340")
            self.assertIs(hook["asyncRewake"], True)
        self.assertTrue(args[args.index("--append-system-prompt") + 1].startswith("You are one, a peer session"))
        text = self.output.getvalue()
        self.assertIn("harness pi; peer harness claude; coordinator pi:parent\nbridge node /opt/node/bin/node\n", text)
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
        args = argv_after_dashes(self.starts()[0])
        self.assertEqual(args[args.index("--permission-mode") + 1], "acceptEdits")
        self.assertIn("--effort=low", args)

    def test_peer_snapshot_failure_exits_cleanly_before_layout(self):
        self.pi_records.side_effect = RuntimeError("bridge list failed")
        with self.assertRaises(SystemExit):
            self.run_main(["--harness", "claude", "--peer-harness", "pi", "one:."],
                          lambda *args, **kwargs: self.fail("created layout"))
        self.assertIn("bridge list failed", self.output.getvalue())

    def test_claude_peer_settings_wake_the_peer_through_bridge_hooks(self):
        self.node.return_value = "/my node/bin/node"
        with patch.dict(os.environ, {"PI_PEER_DIR": "/my peers"}):
            settings = json.loads(fleet.claude_peer_settings("one", "/my repo/bridge.ts"))
        hook = {"type": "command", "timeout": 86400, "asyncRewake": True, "rewakeMessage": "pi-peer bridge",
                "command": "PI_PEER_DIR='/my peers' '/my node/bin/node' '/my repo/bridge.ts' hook --name one --deadline-s 86340"}
        self.assertEqual(settings["hooks"]["SessionStart"], [{"hooks": [hook]}])
        self.assertEqual(settings["hooks"]["Stop"], [{"hooks": [hook]}])

    def claude_peer_ready(self):
        return [{"name": "one", "pid": 111, "messagingSocketPath": "/one.sock"}]

    def test_bridged_claude_coordinator_launches_claude_peers_with_bridge_hooks(self):
        self.bridges[999] = {"address": "pi:boss", "pid": 1000}
        self.bridges[111] = {"address": "pi:one", "pid": 1110}
        with patch.object(fleet, "socket_live", return_value=True):
            self.assertEqual(self.launch(["--harness", "claude", "--model", "haiku", "one:."], self.claude_peer_ready()), 0)
        args = argv_after_dashes(self.starts()[0])
        self.assertEqual(args[args.index("--permission-mode") + 1], "auto")
        self.assertEqual(args.index("--settings"), args.index("--permission-mode") + 2)
        prompt = args[args.index("--append-system-prompt") + 1]
        self.assertEqual(args.index("--append-system-prompt"), args.index("--settings") + 2)
        self.assertTrue(prompt.startswith("You are one, a peer session in an agent fleet"))
        self.assertIn("they grant no new permissions", prompt)
        stop = json.loads(args[args.index("--settings") + 1])["hooks"]["Stop"][0]["hooks"][0]
        self.assertEqual(stop["command"], f"PI_PEER_DIR={self.peer_dir} /opt/node/bin/node /repo/bridge.ts hook --name one --deadline-s 86340")
        self.assertIs(stop["asyncRewake"], True)
        self.assertEqual(args[args.index("--model") + 1], "haiku")
        text = self.output.getvalue()
        self.assertIn("coordinator uds:/fake.sock pi:boss\nbridge node /opt/node/bin/node\n", text)
        self.assertIn("pid 111     uds:/one.sock pi:one", text)
        self.bridge.assert_not_called()

    def bridged_launch(self, specs, bridge_script="/repo/bridge.ts"):
        self.bridge_script = bridge_script
        self.bridges[999] = {"address": "pi:boss", "pid": 1000}
        ready = []
        for index, spec in enumerate(specs):
            name = spec.split(":")[0]
            self.bridges[111 + index] = {"address": f"pi:{name}", "pid": 1110 + index}
            ready.append({"name": name, "pid": 111 + index, "messagingSocketPath": f"/{name}.sock"})
        with patch.object(fleet, "socket_live", return_value=True):
            self.assertEqual(self.launch(["--harness", "claude", *specs], ready), 0)
        return [argv_after_dashes(args) for args in self.starts()]

    def test_bridged_claude_peers_get_their_own_hook_settings(self):
        first, second = self.bridged_launch(["one:.", "two:."])
        self.assertEqual(json.loads(first[first.index("--settings") + 1]), json.loads(fleet.claude_peer_settings("one", "/repo/bridge.ts")))
        self.assertEqual(json.loads(second[second.index("--settings") + 1]), json.loads(fleet.claude_peer_settings("two", "/repo/bridge.ts")))

    def test_unbridged_claude_coordinator_launches_plain_claude_peers(self):
        with patch.object(fleet, "socket_live", return_value=True):
            self.assertEqual(self.launch(["--harness", "claude", "one:."], self.claude_peer_ready()), 0)
        self.assertNotIn("--settings", self.starts()[0])
        self.assertNotIn("--append-system-prompt", self.starts()[0])
        self.assertNotIn("bridge node", self.output.getvalue())
        self.node.assert_not_called()

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

    def test_parse_specs_reads_an_optional_model_after_at(self):
        specs = fleet.parse_specs(["one:.", "two:.@haiku", "three:.@openai-codex/gpt-6-sol:high"])
        self.assertEqual([spec[2] for spec in specs], ["", "haiku", "openai-codex/gpt-6-sol:high"])
        self.assertEqual(specs[1][1], os.path.abspath("."))
        with self.assertRaises(SystemExit):
            fleet.parse_specs(["four:.@"])

    def test_per_peer_model_overrides_the_fleet_model(self):
        ready = [{"name": "one", "pid": 111, "address": "pi:one"}, {"name": "two", "pid": 222, "address": "pi:two"}]
        self.assertEqual(self.launch(["--model", "anthropic/claude-haiku-4-5", "one:.", "two:.@openai-codex/gpt-6-sol:high"], ready), 0)
        models = [args[args.index("--model") + 1] for args in map(argv_after_dashes, self.starts())]
        self.assertEqual(models, ["anthropic/claude-haiku-4-5", "openai-codex/gpt-6-sol:high"])

    def test_peer_without_a_model_gets_no_model_flag(self):
        self.assertEqual(self.launch(["one:."], [{"name": "one", "pid": 111, "address": "pi:one"}]), 0)
        self.assertNotIn("--model", argv_after_dashes(self.starts()[0]))


if __name__ == "__main__":
    unittest.main()
