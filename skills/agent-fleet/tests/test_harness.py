import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))
import harness

PEER = {
    "version": 1, "instanceId": "0f8fad5b-d9cb-469f-a165-70867728950e",
    "address": "pi:0f8fad5b-d9cb-469f-a165-70867728950e", "sessionId": "s1", "name": "one",
    "cwd": "/w", "pid": 4242, "terminalId": "t2", "socketPath": "/tmp/pi-peer-1/x.sock",
}


def node(returncode=0, stdout="", stderr=""):
    return patch.object(harness.subprocess, "run", return_value=subprocess.CompletedProcess([], returncode, stdout, stderr))


class PiRecordsTests(unittest.TestCase):
    def setUp(self):
        for name, value in (("bridge_script", "/repo/bridge.ts"), ("bridge_node", "/opt/node/bin/node")):
            patcher = patch.object(harness, name, return_value=value)
            patcher.start()
            self.addCleanup(patcher.stop)

    def test_parses_bridge_list_output(self):
        with node(stdout=json.dumps([PEER])) as run:
            self.assertEqual(harness.pi_records(), [PEER])
        self.assertEqual(run.call_args.args[0], ["/opt/node/bin/node", "/repo/bridge.ts", "list", "--json"])

    def test_node_failure_raises_instead_of_reporting_no_peers(self):
        for returncode, stdout in ((1, "[]"), (0, "not json"), (0, '{"peers": []}')):
            with self.subTest(returncode=returncode, stdout=stdout), node(returncode, stdout, "boom"):
                with self.assertRaises(RuntimeError):
                    harness.pi_records()

    def test_spawn_oserror_raises(self):
        with patch.object(harness.subprocess, "run", side_effect=FileNotFoundError("node")):
            with self.assertRaises(RuntimeError):
                harness.pi_records()


class BridgeNodeTests(unittest.TestCase):
    def setUp(self):
        harness.bridge_node.cache_clear()
        self.addCleanup(harness.bridge_node.cache_clear)
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = directory.name
        self.calls = Path(self.root) / "calls"

    def fake_node(self, directory, version, exec_path=None, body=None):
        path = Path(self.root) / directory / "node"
        path.parent.mkdir(parents=True, exist_ok=True)
        body = body or f"echo '{exec_path or path}'\necho {version}"
        path.write_text(f"#!/bin/sh\n[ \"$1\" = -p ] || exit 9\necho x >> '{self.calls}'\n{body}\n")
        path.chmod(0o755)
        return str(path)

    def env(self, path_dir, peer_node=None):
        env = {"PATH": str(Path(self.root) / path_dir)}
        if peer_node is not None:
            env["PI_PEER_NODE"] = peer_node
        stack = patch.dict(os.environ, env)
        stack.start()
        self.addCleanup(stack.stop)
        if peer_node is None:
            os.environ.pop("PI_PEER_NODE", None)

    def test_resolves_path_node_to_absolute_path(self):
        node_path = self.fake_node("bin", "22.18.0")
        self.env("bin")
        self.assertEqual(harness.bridge_node(), node_path)
        self.assertTrue(os.path.isabs(harness.bridge_node()))

    def test_checks_the_version_once_per_process(self):
        self.fake_node("bin", "22.18.0")
        self.env("bin")
        harness.bridge_node()
        harness.bridge_node()
        self.assertEqual(self.calls.read_text().count("x"), 1)

    def test_pi_peer_node_wins_over_older_path_node(self):
        self.fake_node("bin", "20.0.0")
        newer = self.fake_node("newer", "24.3.0")
        self.env("bin", newer)
        self.assertEqual(harness.bridge_node(), newer)

    def test_accepts_boundary_and_newer_versions(self):
        for version in ("22.18.0", "22.19.1", "24.0.0", "25.1.0"):
            with self.subTest(version=version):
                harness.bridge_node.cache_clear()
                node_path = self.fake_node(version, version)
                self.env("none", node_path)
                self.assertEqual(harness.bridge_node(), node_path)

    def test_homebrew_cellar_node_resolves_to_the_stable_opt_path(self):
        cellar = self.fake_node("homebrew/Cellar/node/26.8.2/bin", "26.8.2")
        stable = self.fake_node("homebrew/opt/node/bin", "26.13.0")
        self.fake_node("bin", "26.8.2", exec_path=cellar)
        self.env("bin")
        self.assertEqual(harness.bridge_node(), stable)

    def test_keeps_the_cellar_path_when_no_opt_link_exists(self):
        cellar = self.fake_node("homebrew/Cellar/node/26.8.2/bin", "26.8.2")
        self.fake_node("bin", "26.8.2", exec_path=cellar)
        self.env("bin")
        self.assertEqual(harness.bridge_node(), cellar)

    def test_returns_the_binary_a_shim_runs_not_the_shim(self):
        real = self.fake_node("tools/node/24.3.0/bin", "24.3.0")
        self.fake_node("shims", "24.3.0", exec_path=real)
        self.env("shims")
        self.assertEqual(harness.bridge_node(), real)

    def test_shim_reports_old_binary_by_its_real_path(self):
        self.fake_node("shims", "22.15.0", exec_path="/tools/node/22.15.0/bin/node")
        self.env("shims")
        with self.assertRaises(RuntimeError) as caught:
            harness.bridge_node()
        self.assertEqual(str(caught.exception), "pi-peer bridge needs Node 22.18+; /tools/node/22.15.0/bin/node is v22.15.0. "
                         "Set PI_PEER_NODE to a newer node.")

    def test_failed_node_reports_its_stderr(self):
        shim = self.fake_node("shims", "", body="echo 'node 24 is not installed' >&2\nexit 1")
        self.env("shims")
        with self.assertRaises(RuntimeError) as caught:
            harness.bridge_node()
        self.assertEqual(str(caught.exception), f"pi-peer bridge needs Node 22.18+; {shim} could not report its version: "
                         "node 24 is not installed. Set PI_PEER_NODE to a newer node.")

    def test_probe_that_hangs_or_cannot_start_reports_the_error(self):
        node_path = self.fake_node("hang", "24.3.0")
        self.env("hang")
        for error in (subprocess.TimeoutExpired(cmd=node_path, timeout=10), OSError("Exec format error")):
            with self.subTest(error=type(error).__name__):
                harness.bridge_node.cache_clear()
                with patch.object(harness.subprocess, "run", side_effect=error):
                    with self.assertRaises(RuntimeError) as caught:
                        harness.bridge_node()
                self.assertEqual(str(caught.exception), f"pi-peer bridge needs Node 22.18+; {node_path} could not report its version: "
                                 f"{error}. Set PI_PEER_NODE to a newer node.")

    def test_old_node_raises_naming_path_version_and_override(self):
        for version in ("22.15.0", "22.17.9"):
            with self.subTest(version=version):
                harness.bridge_node.cache_clear()
                node_path = self.fake_node(version, version)
                self.env("none", node_path)
                with self.assertRaises(RuntimeError) as caught:
                    harness.bridge_node()
                self.assertEqual(str(caught.exception),
                                 f"pi-peer bridge needs Node 22.18+; {node_path} is v{version}. Set PI_PEER_NODE to a newer node.")

    def test_missing_node_raises(self):
        for peer_node, named in ((None, "node"), ("/nowhere/node", "/nowhere/node")):
            with self.subTest(peer_node=peer_node):
                harness.bridge_node.cache_clear()
                self.env("empty", peer_node)
                with self.assertRaises(RuntimeError) as caught:
                    harness.bridge_node()
                self.assertEqual(str(caught.exception),
                                 f"pi-peer bridge needs Node 22.18+; {named} not found. Set PI_PEER_NODE to a Node 22.18+ binary.")


class BridgeScriptTests(unittest.TestCase):
    def test_prefers_repo_copy(self):
        repo = Path(__file__).resolve().parents[3] / "pi/extensions/pi-peer/bridge.ts"
        with patch.object(Path, "is_file", lambda path: path == repo):
            self.assertEqual(harness.bridge_script(), str(repo))

    def test_falls_back_to_installed_extension(self):
        with tempfile.TemporaryDirectory() as root:
            installed = Path(root) / "extensions/pi-peer/bridge.ts"
            with patch.dict(os.environ, {"PI_CODING_AGENT_DIR": root}), \
                    patch.object(Path, "is_file", lambda path: path == installed):
                self.assertEqual(harness.bridge_script(), str(installed))

    def test_missing_bridge_raises(self):
        with patch.object(Path, "is_file", lambda path: False):
            with self.assertRaises(RuntimeError):
                harness.bridge_script()


class PiExtensionTests(unittest.TestCase):
    repo = Path(__file__).resolve().parents[3] / "pi/extensions/pi-peer/index.ts"

    def test_prefers_installed_extension_over_repo_copy(self):
        self.assertTrue(self.repo.is_file())
        with tempfile.TemporaryDirectory() as root:
            installed = Path(root) / "extensions/pi-peer/index.ts"
            installed.parent.mkdir(parents=True)
            installed.write_text("")
            with patch.dict(os.environ, {"PI_CODING_AGENT_DIR": root}):
                self.assertEqual(harness.pi_extension(), str(installed))

    def test_falls_back_to_repo_copy_when_nothing_installed(self):
        with tempfile.TemporaryDirectory() as root, patch.dict(os.environ, {"PI_CODING_AGENT_DIR": root}):
            self.assertEqual(harness.pi_extension(), str(self.repo))


if __name__ == "__main__":
    unittest.main()
