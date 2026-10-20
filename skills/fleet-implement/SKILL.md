---
name: fleet-implement
description: Implement a spec with an agent fleet in Herdr tabs - Claude implementers running /implement, GPT adversarial auditors, a final Opus + Sol deep review triaged by Fable or Astra, this session as coordinator.
disable-model-invocation: true
argument-hint: "<spec path | ticket id | pasted spec> (empty: read the clipboard with pbpaste)"
---

# Fleet implement

Implement the spec with `/agent-fleet` as coordinator, `/implement` on each implementation track, and a cross-family adversarial audit of every track. The spec is the argument; with none, read it from the clipboard with `pbpaste`. A ticket id is fetched from the tracker and its title stated before anything else.

This session is the coordinator. It plans, briefs, relays, decides, and reports. Peers and subagents do the work.

## Roster

Claude peers (default harness; the model is the alias after `@`):

- `fable` — ambiguous specs, cross-module design, work where the shape of the interface is still open.
- `opus` — default implementer for tracks with design judgment.
- `sonnet` — well-specified mechanical tracks: a known pattern applied to new files, DTO and schema work, test fixtures.
- `haiku` — trivial one-file changes and renames. Implementer only.

GPT peers (`--peer-harness pi`; the model is `openai-codex/<id>[:thinking]`):

- `gpt-6-astra:high` — deepest adversarial auditor: plan critique, intent audit of the riskiest track.
- `gpt-6.1-sol:high` — default auditor: feasibility and fact-checks against the code, 500k context for large diffs, catches invented behaviour and unverified claims.
- `gpt-5.6-terra` — previous-generation mid tier, the fallback when sol is unavailable.
- `gpt-6-luna` — cheapest: checklist sweeps, log and output summarising. Implementer-side chores only.

These roles are working assignments from price tier and past runs, not benchmarks. Adjust when a run shows a model doing better or worse than its line.

Rules:

- An auditor comes from the other model family than its implementer: a Claude track gets sol or astra, a GPT track gets opus.
- The `/review-code quick` inside `/implement` is same-family self-review. The audit is in addition to it.
- A GPT peer implements a track only when its brief inlines what `/implement` and `/tdd` would supply: pre-agreed seams, red before green, one slice at a time, the project's lint and test commands, and the commit step. Pi peers have none of those skills.

## Subagents

Use a peer when the work needs another model family or a back-and-forth. Give one-shot chores with a single reply to a native subagent: the `Agent` tool with `run_in_background: true`. The coordinator's context then holds summaries, not logs.

- Reading a large spec, handoff, or ticket before planning: return candidate tracks and write scopes.
- Integrating track branches, and applying the triage fixes: a write-capable subagent that commits and returns the commits.
- Repo-wide lint and full test runs: return pass or fail and only the failing excerpts.

Dispatch, end the turn, and act on the summary when it arrives.

## 1. Plan

- Split the spec into independent tracks with disjoint write scopes. Serialize anything that cannot be made disjoint.
- Assign each track an implementer and an auditor from the roster, one line of reasoning each.
- Per `/tdd`, propose the seams each track tests at, one line on what each catches and misses. Agreeing them here keeps every peer from stopping to ask separately.
- Show the user the tracks, assignments, and seams, then launch. Ask only when the split is genuinely ambiguous.

## 2. Launch

Read the `agent-fleet` skill and follow its preflight. Then spawn with `--placement tab --per-tab 2 --title "<mission in five words or fewer>"`, one `NAME:DIR@MODEL` per peer.

Order matters: launch the GPT peers first with `--peer-harness pi`, which starts the bridge, then the Claude peers in a second call. Claude peers launched after the bridge exists get its hooks, so auditors can message them directly.

Peers writing to the same checkout each get their own worktree and branch, initialized the way the project's `AGENTS.md` says.

## 3. Brief

Implementer brief:

- The track's slice of the spec, or its path.
- Directory, branch, and exact write scope.
- The agreed seams.
- Run `/implement`: tdd, typecheck and single-file tests as it goes, `/review-code quick`, fix Blocker and Major findings, commit.
- Reply format: commits, files touched, test results, anything skipped or blocked.
- The coordinator's literal return address from `peer-addr.py --me`: `uds:` for a Claude peer, `pi:` for a GPT peer, which replies with `bridge.ts send`.

Auditor brief, sent when its implementer replies:

- The spec slice and the commit range.
- The intent question: did the diff deliver what the spec promised, what did it invent, what did it skip.
- Read-only. Findings ranked Blocker, Major, Minor with `file:line`. Reply once.

Confirmed Blocker and Major findings go back to the implementer for one fix round. After that the coordinator decides and records the decision in the report.

Send the briefs, re-arm `bridge.ts wait` in the background, and end the turn. Replies wake the coordinator. A send receipt means accepted, so a peer that has not replied is still working.

## 4. Integrate

Done here means every track is implemented, audited, and integrated:

1. A subagent integrates the track branches onto the current branch.
2. A subagent runs the project's repo-wide lint and full test suite.
3. Tear down the implementer and auditor peers per `agent-fleet`: kill PIDs, close only the tabs the launcher created, confirm with `peer-addr.py`. Leave the bridge running; the final reviewers need it.

## 5. Final review

The final review runs once per implementation. It is slow and expensive, so never rerun it: not after the triage fixes, not after a failing test, not to confirm a fix. Fixes made after it are checked by lint and tests alone.

Two fresh peers review the combined diff with `deep-review-code`, one from each family, in one tab titled `final review`:

- `opus` reviewer.
- `gpt-6.1-sol:high` reviewer, launched first with `--peer-harness pi`.

Pick the mode once and give both the same one. `full` when the diff is large, crosses module boundaries, or touches auth, data, migrations, or a public API. `quick` otherwise. State the choice and the reason in one line.

Reviewer brief:

- Read `~/.agents/skills/deep-review-code/SKILL.md` and follow the `<mode>` mode. Reading the file works for both harnesses; the skill cannot be invoked by a peer.
- The resolved scope, verbatim: `git diff <merge-base>...HEAD` at head `<sha>`, and the spec path for the intent lens.
- Read-only. Reply once with the full report.

## 6. Triage

When both reports are in, spawn one triage peer: `gpt-6-astra:high` when most of the implementation came from Claude peers, `fable` when it came from GPT peers. Send it the spec, the scope, and both reports.

Triage brief:

- Merge findings that share a root cause.
- Mark each finding **fix** or **drop**. Fix a defect a user or caller would hit, or a spec promise the diff does not keep. Drop speculative hardening, new abstractions or configuration, tests for states the code cannot reach, and style the repo's standards do not require.
- For each fix, name the smallest change at `file:line`. For each drop, one line of why.
- Read-only. Reply once.

A subagent applies the fixes, then reruns lint and the full test suite. Do not send the fixes back to the reviewers or the triage peer.

## 7. Finish

1. Report what landed, what was skipped, which commits came from which track, each auditor's verdict, both final review verdicts, and the triage list with what was fixed and what was dropped.
2. Tear down the final review and triage peers per `agent-fleet`, stop the bridge last, and confirm with `peer-addr.py`. Keep them only when the user asked.
