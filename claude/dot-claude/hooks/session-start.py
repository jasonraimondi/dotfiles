#!/usr/bin/env dev-uvshebang
import json
import sys
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path

import typer

SCRIPT_PATH = Path(__file__)
PLUGIN_ROOT = SCRIPT_PATH.parent.parent
SESSION_START_MD = SCRIPT_PATH.parent / "session-start.md"


def read_file(file_path: Path) -> str:
    """Read file content with graceful error handling."""
    try:
        with open(file_path, "r") as f:
            return f.read()
    except FileNotFoundError:
        return ""
    except Exception as e:
        print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)
        return ""


@contextmanager
def hook_invocation_logger():
    input_data = json.load(sys.stdin)
    additional_context = None

    def set_additional_context(context: str):
        nonlocal additional_context
        additional_context = context

    yield set_additional_context

    output = None
    if additional_context is not None:
        output = {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": additional_context,
            }
        }

    # Write log payload to file
    try:
        with open(SCRIPT_PATH.parent / "hooks.jsonl", "a") as f:
            json.dump(
                {
                    "cwd": str(Path.cwd()),
                    "ts": str(datetime.now()),
                    "in": input_data,
                    "out": output,
                },
                f,
            )
            _ = f.write("\n")
    except Exception as e:
        print(f"Warning: Could not write to log file: {e}", file=sys.stderr)

    if output is not None:
        json.dump(output, sys.stdout)


def main():
    with hook_invocation_logger() as set_context:
        md_txt = read_file(SESSION_START_MD).strip()
        if md_txt:
            set_context(md_txt)


if __name__ == "__main__":
    typer.run(main)
