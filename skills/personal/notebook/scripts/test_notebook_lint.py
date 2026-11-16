import datetime
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

LINT = Path(__file__).resolve().parent / "notebook-lint"
TODAY = datetime.date.today()
STAMP = TODAY.strftime("%Y-%m-%d") + "-1000"
LATER = TODAY.strftime("%Y-%m-%d") + "-1100"
HANDOFF = f"{STAMP}-handoff-demo-start"

PAGE = f"""---
type: topic
status: active
tickets: [ABC-1]
---
# Demo

Resume: [[{HANDOFF}]]

## State
- started

## Decisions
- none

## Open
- none

## Sources
- [[{HANDOFF}]] — first handoff
"""


def note(kind, topic="demo", status="active", body="Body.\n", tickets="[ABC-1]"):
    return f"---\ntype: {kind}\ntopic: {topic}\ntickets: {tickets}\nstatus: {status}\n---\n{body}"


def clean_vault():
    return {
        "index.md": "## Active\n- [[demo]] — a demo topic\n",
        "topics/demo/demo.md": PAGE,
        f"topics/demo/{HANDOFF}.md": note("handoff"),
    }


class LintCase(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()

    def write(self, files):
        for rel, content in files.items():
            path = self.root / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            if isinstance(content, bytes):
                path.write_bytes(content)
            else:
                path.write_text(content)

    def git(self, *args):
        subprocess.run(["git", "-C", str(self.root), *args], check=True, capture_output=True)

    def git_init(self):
        self.git("init", "-q")
        self.git("config", "user.email", "t@example.com")
        self.git("config", "user.name", "t")

    def lint(self, *args):
        env = {k: v for k, v in os.environ.items() if k != "AI_NOTEBOOK_PATH"}
        return subprocess.run(
            [sys.executable, str(LINT), "--root", str(self.root), *args],
            capture_output=True, text=True, env=env,
        )

    def codes(self, result):
        out = result.stdout + result.stderr
        return {tok for tok in out.split() if tok.startswith(("E-", "W-"))}


class CleanAndSize(LintCase):
    def test_clean_topic_passes(self):
        self.write(clean_vault())
        r = self.lint()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual(self.codes(r), set())

    def test_large_file_under_topics_fails_size(self):
        self.write(clean_vault())
        self.write({"topics/demo/artifacts/big.txt": "a" * 1_100_000})
        r = self.lint()
        self.assertEqual(r.returncode, 1)
        self.assertIn("E-size", self.codes(r))
        self.assertIn("topics/demo/artifacts/big.txt", r.stdout)

    def test_large_tracked_file_fails_size_in_git_vault(self):
        self.write(clean_vault())
        self.write({"topics/demo/artifacts/big.txt": "a" * 1_100_000})
        self.git_init()
        self.git("add", "-A")
        self.git("commit", "-qm", "init")
        r = self.lint()
        self.assertIn("E-size", self.codes(r))

    def test_ignored_large_file_is_not_checked(self):
        self.write(clean_vault())
        self.write({"topics/demo/artifacts/big.txt": "a" * 1_100_000, ".gitignore": "big.txt\n"})
        self.git_init()
        r = self.lint()
        self.assertEqual(r.returncode, 0, r.stdout)

    def test_text_under_one_mb_passes(self):
        self.write(clean_vault())
        self.write({"topics/demo/artifacts/ok.txt": "a" * 900_000})
        r = self.lint()
        self.assertEqual(r.returncode, 0, r.stdout)

    def test_binary_under_topics_fails_size(self):
        self.write(clean_vault())
        self.write({"topics/demo/artifacts/shot.png": b"\x89PNG\x00\x01\x02"})
        r = self.lint()
        self.assertEqual(r.returncode, 1)
        self.assertIn("E-size", self.codes(r))

    def test_raw_capture_and_ds_store_fail_raw(self):
        self.write(clean_vault())
        self.write({"topics/demo/artifacts/call.req": "GET /\n", "topics/demo/.DS_Store": "x"})
        r = self.lint()
        self.assertEqual(r.returncode, 1)
        self.assertIn("topics/demo/artifacts/call.req", r.stdout)
        self.assertIn("topics/demo/.DS_Store", r.stdout)
        self.assertIn("E-raw", self.codes(r))


class Names(LintCase):
    def check(self, name, content, code):
        self.write(clean_vault())
        self.write({f"topics/demo/{name}": content})
        r = self.lint()
        self.assertEqual(r.returncode, 1)
        self.assertIn(code, self.codes(r))
        self.assertIn(name, r.stdout)

    def test_snake_case_fails_name(self):
        self.check(f"{STAMP}-research-snake_case_note.md", note("research"), "E-name")

    def test_missing_hhmm_fails_name(self):
        self.check(f"{TODAY:%Y-%m-%d}-research-no-time.md", note("research"), "E-name")

    def test_unknown_kind_fails_name(self):
        self.check(f"{STAMP}-memo-thing.md", note("memo"), "E-name")

    def test_kind_not_matching_type_fails_front(self):
        self.check(f"{STAMP}-plan-thing.md", note("research"), "E-front")

    def test_topic_not_matching_folder_fails_front(self):
        self.check(f"{STAMP}-plan-thing.md", note("plan", topic="other"), "E-front")

    def test_invalid_status_fails_front(self):
        self.check(f"{STAMP}-plan-thing.md", note("plan", status="wip"), "E-front")

    def test_missing_frontmatter_fails_front(self):
        self.check(f"{STAMP}-plan-thing.md", "No frontmatter.\n", "E-front")

    def test_page_with_bad_status_fails_front(self):
        self.write(clean_vault())
        self.write({"topics/demo/demo.md": PAGE.replace("status: active", "status: wip")})
        r = self.lint()
        self.assertIn("E-front", self.codes(r))


class Links(LintCase):
    def with_body(self, body):
        self.write(clean_vault())
        self.write({f"topics/demo/{LATER}-research-links.md": note("research", body=body)})
        self.write({"topics/demo/demo.md": PAGE + f"- [[{LATER}-research-links]]\n"})
        return self.lint()

    def test_missing_stem_fails_link(self):
        r = self.with_body("See [[missing-stem]].\n")
        self.assertEqual(r.returncode, 1)
        self.assertIn("E-link", self.codes(r))
        self.assertIn("missing-stem", r.stdout)

    def test_bash_test_in_fenced_block_is_not_a_link(self):
        r = self.with_body('```bash\nif [[ -z "$1" ]]; then exit; fi\n```\n')
        self.assertEqual(r.returncode, 0, r.stdout)

    def test_inline_code_is_not_a_link(self):
        r = self.with_body('Run `[[ -z "$1" ]]` first.\n')
        self.assertEqual(r.returncode, 0, r.stdout)

    def test_alias_heading_and_archive_targets_resolve(self):
        self.write({"archive/legacy/research/old-note.md": "old\n"})
        r = self.with_body(f"[[demo|the page]] [[{HANDOFF}#Open]] [[old-note]]\n")
        self.assertEqual(r.returncode, 0, r.stdout)

    def test_bulk_path_fails_when_absent(self):
        r = self.with_body("Dump at `_bulk/x/y.json`.\n")
        self.assertEqual(r.returncode, 1)
        self.assertIn("_bulk/x/y.json", r.stdout)

    def test_bulk_path_passes_when_present(self):
        self.write({"_bulk/x/y.json": "{}"})
        r = self.with_body("Dump at `_bulk/x/y.json`.\n")
        self.assertEqual(r.returncode, 0, r.stdout)

    def test_markdown_link_to_missing_file_fails(self):
        r = self.with_body("[trace](artifacts/trace.txt)\n")
        self.assertIn("E-link", self.codes(r))

    def test_markdown_link_to_present_file_passes(self):
        self.write({"topics/demo/artifacts/trace.txt": "t"})
        r = self.with_body("[trace](artifacts/trace.txt) [site](<https://example.com>) Put dumps in `_bulk/<slug>/`.\n")
        self.assertEqual(r.returncode, 0, r.stdout)


class Pages(LintCase):
    def test_topic_folder_without_page_fails(self):
        self.write(clean_vault())
        self.write({f"topics/lost/{STAMP}-plan-x.md": note("plan", topic="lost")})
        r = self.lint()
        self.assertIn("E-page", self.codes(r))
        self.assertIn("topics/lost/", r.stdout)

    def test_page_missing_section_fails(self):
        self.write(clean_vault())
        self.write({"topics/demo/demo.md": PAGE.replace("## Open", "## Later")})
        r = self.lint()
        self.assertEqual(r.returncode, 1)
        self.assertIn("E-page", self.codes(r))

    def test_unexpected_root_entries_fail(self):
        self.write(clean_vault())
        self.write({"stray.md.md": "x\n", "scratch/a.md": "x\n", "backlog.md": "x\n"})
        r = self.lint()
        self.assertEqual(r.returncode, 1)
        roots = [l for l in r.stdout.splitlines() if l.startswith("E-root")]
        self.assertEqual(len(roots), 2, r.stdout)
        self.assertIn("stray.md.md", r.stdout)
        self.assertIn("scratch/", r.stdout)


class Warnings(LintCase):
    def test_note_missing_from_sources_warns_only(self):
        self.write(clean_vault())
        self.write({f"topics/demo/{LATER}-research-extra.md": note("research")})
        r = self.lint()
        self.assertEqual(r.returncode, 0, r.stdout)
        self.assertEqual(self.codes(r), {"W-sources"})

    def test_resume_on_superseded_handoff_warns(self):
        newer = f"{LATER}-handoff-demo-next"
        self.write(clean_vault())
        self.write({
            f"topics/demo/{HANDOFF}.md": note("handoff", status="superseded"),
            f"topics/demo/{newer}.md": note("handoff"),
            "topics/demo/demo.md": PAGE + f"- [[{newer}]]\n",
        })
        r = self.lint()
        self.assertEqual(r.returncode, 0, r.stdout)
        self.assertEqual(self.codes(r), {"W-resume"})

    def test_resume_on_newest_handoff_is_clean(self):
        newer = f"{LATER}-handoff-demo-next"
        self.write(clean_vault())
        self.write({
            f"topics/demo/{HANDOFF}.md": note("handoff", status="superseded"),
            f"topics/demo/{newer}.md": note("handoff"),
            "topics/demo/demo.md": PAGE.replace(f"Resume: [[{HANDOFF}]]", f"Resume: [[{newer}]]") + f"- [[{newer}]]\n",
        })
        r = self.lint()
        self.assertEqual(self.codes(r), set(), r.stdout)

    def test_index_drift_warns(self):
        self.write(clean_vault())
        self.write({
            "index.md": f"- [[backlog]] — parked\n- [[{HANDOFF}]] — a note, not a page\n- " + "x" * 130 + "\n",
            "backlog.md": "b\n",
        })
        r = self.lint()
        self.assertEqual(r.returncode, 0, r.stdout)
        index = [l for l in r.stdout.splitlines() if l.startswith("W-index")]
        self.assertEqual(len(index), 3, r.stdout)

    def test_inbox_notes_sharing_a_ticket_warn(self):
        self.write(clean_vault())
        self.write({
            f"inbox/{STAMP}-research-pnpm-a.md": note("research", topic="inbox", tickets="[ENG-9, ABC-2]"),
            f"inbox/{LATER}-research-pnpm-b.md": note("research", topic="inbox", tickets="[ABC-2]"),
        })
        r = self.lint()
        self.assertEqual(r.returncode, 0, r.stdout)
        self.assertEqual(self.codes(r), {"W-inbox"})
        self.assertIn("ABC-2", r.stdout)

    def test_inbox_notes_with_distinct_tickets_are_clean(self):
        self.write(clean_vault())
        self.write({
            f"inbox/{STAMP}-research-a.md": note("research", topic="inbox", tickets="[ABC-2]"),
            f"inbox/{LATER}-research-b.md": note("research", topic="inbox", tickets="[]"),
        })
        r = self.lint()
        self.assertEqual(self.codes(r), set(), r.stdout)

    def test_inbox_note_topic_must_be_inbox(self):
        self.write(clean_vault())
        self.write({f"inbox/{STAMP}-research-a.md": note("research", topic="pnpm")})
        r = self.lint()
        self.assertEqual(r.returncode, 1)
        self.assertIn("E-front", self.codes(r))

    def test_non_note_file_beside_notes_fails_but_under_artifacts_passes(self):
        self.write(clean_vault())
        self.write({f"topics/demo/artifacts/{STAMP}-run/known-failures.md": "list\n"})
        self.assertEqual(self.lint().returncode, 0)
        self.write({"topics/demo/known-failures.md": "list\n"})
        r = self.lint()
        self.assertEqual(r.returncode, 1)
        self.assertIn("E-name", self.codes(r))

    def test_done_or_stale_topic_warns_archive(self):
        old = (TODAY - datetime.timedelta(days=40)).strftime("%Y-%m-%d") + "-0900"
        self.write({
            "index.md": "- [[demo]] — demo\n- [[gone]] — gone\n",
            "topics/demo/demo.md": PAGE.replace("status: active", "status: done"),
            f"topics/demo/{HANDOFF}.md": note("handoff"),
            "topics/gone/gone.md": PAGE.replace(HANDOFF, f"{old}-handoff-gone"),
            f"topics/gone/{old}-handoff-gone.md": note("handoff", topic="gone"),
        })
        r = self.lint()
        archive = [l for l in r.stdout.splitlines() if l.startswith("W-archive")]
        self.assertEqual(len(archive), 2, r.stdout)


class Archive(LintCase):
    def test_archive_produces_no_findings(self):
        self.write(clean_vault())
        self.write({
            "archive/legacy/research/bad_name.md": "[[nowhere]]\n",
            "archive/legacy/research/big.bin": b"\x00" * 1_100_000,
            "archive/legacy/.DS_Store": "x",
            "archive/topics/old/notes.md": "no page here\n",
        })
        r = self.lint()
        self.assertEqual(r.returncode, 0, r.stdout)
        self.assertEqual(self.codes(r), set())


class Staged(LintCase):
    def test_staged_prints_exactly_the_rejected_staged_paths(self):
        self.write(clean_vault())
        self.git_init()
        self.git("add", "-A")
        self.git("commit", "-qm", "init")
        bad = f"topics/demo/{LATER}-plan-bad.md"
        self.write({
            bad: note("research", body="[[missing-stem]]\n"),
            "topics/demo/artifacts/big.txt": "a" * 1_100_000,
            "topics/demo/artifacts/small.txt": "fine",
            "scratch/unstaged.md": "[[missing-stem]]\n",
        })
        self.git("add", bad, "topics/demo/artifacts/big.txt", "topics/demo/artifacts/small.txt")
        r = self.lint("--staged")
        self.assertEqual(r.returncode, 1)
        self.assertEqual(sorted(r.stdout.split()), sorted([bad, "topics/demo/artifacts/big.txt"]))
        self.assertIn("E-size", r.stderr)
        self.assertNotIn("scratch", r.stdout + r.stderr)

    def test_staged_clean_exits_zero_with_empty_stdout(self):
        self.write(clean_vault())
        self.git_init()
        self.git("add", "-A")
        r = self.lint("--staged")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout, "")

    def test_staged_rejects_file_under_unexpected_root(self):
        self.write(clean_vault())
        self.git_init()
        self.write({"scratch/a.md": "x\n"})
        self.git("add", "-A")
        r = self.lint("--staged")
        self.assertEqual(r.returncode, 1)
        self.assertEqual(r.stdout.split(), ["scratch/a.md"])


class Report(LintCase):
    def test_report_written_at_vault_root(self):
        self.write(clean_vault())
        self.write({"topics/demo/artifacts/big.txt": "a" * 1_100_000})
        r = self.lint("--report", "lint.md")
        self.assertEqual(r.returncode, 1)
        report = (self.root / "lint.md").read_text()
        self.assertIn("E-size", report)
        self.assertIn("topics/demo/artifacts/big.txt", report)


if __name__ == "__main__":
    unittest.main()
