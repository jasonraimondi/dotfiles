---
name: mdlr
description: Use whenever the user requests you to use the cli tool `mdlr` to check or improve the modularity of the codebase.
allowed-tools: Bash(mdlr:*)
---

# mdlr

A modularity/code-quality analyzer. Surfaces functions, structs, and files that are hard to
understand, test, or maintain, ranked by metric.

## Prerequisites

The `mdlr` command must be on PATH. To check:

```bash
mdlr --version
```

## Available Commands

```bash
mdlr check [TARGET]      # run analysis, print opportunities
mdlr metrics ls          # list all metrics with descriptions
mdlr metrics get <name>  # thresholds for one metric
mdlr prompt               # emit mdlr's own markdown "auto-improve" playbook
mdlr ls [PATH]            # list symbols (functions/methods/structs) in a file or dir
mdlr get <SYMBOL_ID>      # print a symbol's source
mdlr ignore [METRIC] [SYMBOL] --list --remove   # human-only, see below
```

Global flag: `--root <ROOT>` (skip auto-discovery of the project root).

### `mdlr check`

```
mdlr check [OPTIONS] [TARGET]

  -k <K>            max opportunities per metric, -1 for all (default 10)
  -A, --all         analyze all files, ignoring diff-mode scoping
  -f, --filter DIR  scope analysis to a directory
      --cov PATH    overlay an LCOV coverage file (repeatable)
      --pretty      aligned table output
      --format      text|json (default text)
```

**Scope auto-selects from git state**: uncommitted changes → diff of dirty files; clean
feature branch → diff vs main/master; clean main/master → whole project. This means a plain
`mdlr check` already behaves like "review what I just touched" — pass `-A` only when you
deliberately want a whole-project sweep regardless of branch state.

### `mdlr ignore` is human-only

`mdlr ignore` refuses to run outside an interactive terminal (`Error: mdlr ignore is only
available in interactive (human) mode`). Don't try to suppress a false positive yourself —
tell the user which metric/symbol looks like a false positive and let them run `mdlr ignore`
themselves.

## Workflow

1. Check for staged or unstaged changes. If there are any, commit them first with a
   reasonable message — `mdlr check`'s diff-mode scoping depends on a clean working tree to
   correctly detect "changes vs. main."
2. Run `mdlr check --pretty` (add `-f <dir>` to scope to a subdirectory, `-A` for a full
   sweep). Read the opportunities table.
3. For real fixes (not just a report), run `mdlr prompt` for mdlr's own suggested playbook —
   but **adapt it to this repo**: `mdlr prompt`'s text assumes mdlr's own Rust project
   (`cargo test`, `cargo llvm-cov`); substitute this project's actual test/typecheck/coverage
   commands instead of following those literally.
4. Make a task list for any large change before starting.
5. **You MUST commit all changes after finishing. Do not skip this step. Do not end without
   committing.**

## Commit messages

The commit message for post-mdlr changes MUST include "auto" somewhere, and name the metric
and target improved:

```bash
git add <changed files>
git commit -m "refactor: auto-reduce <metric> of <target>"
```
