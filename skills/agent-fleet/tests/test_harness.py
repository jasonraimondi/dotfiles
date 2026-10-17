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
    "cwd": "/w", "pid": 4242, "paneId": "test:p2", "socketPath": "/tmp/pi-peer-1/x.sock",
}


def node(returncode=0, stdout="", stderr=""):
    return patch.object(harness.subprocess, "run", return_value=subprocess.CompletedProcess([], returncode, stdout, stderr))


class PiRecordsTests(unittest.TestCase):
    def setUp(self):
        patcher = patch.object(harness, "bridge_script", return_value="/repo/bridge.ts")
        patcher.start()
        self.addCleanup(patcher.stop)

    def test_parses_bridge_list_output(self):
        with node(stdout=json.dumps([PEER])) as run:
            self.assertEqual(harness.pi_records(), [PEER])
        self.assertEqual(run.call_args.args[0], ["node", "/repo/bridge.ts", "list", "--json"])

    def test_node_failure_raises_instead_of_reporting_no_peers(self):
        for returncode, stdout in ((1, "[]"), (0, "not json"), (0, '{"peers": []}')):
            with self.subTest(returncode=returncode, stdout=stdout), node(returncode, stdout, "boom"):
                with self.assertRaises(RuntimeError):
                    harness.pi_records()

    def test_missing_node_raises(self):
        with patch.object(harness.subprocess, "run", side_effect=FileNotFoundError("node")):
            with self.assertRaises(RuntimeError):
                harness.pi_records()


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
