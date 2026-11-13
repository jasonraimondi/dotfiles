---
name: fleet-implement
description: Implement a spec with an agent fleet in herdr-core terminals - Claude implementers running /implement, GPT adversarial auditors, a final Opus + Sol deep review triaged by Fable or Astra, this session as coordinator.
disable-model-invocation: true
argument-hint: "<spec path | ticket id | pasted spec> (empty: read the clipboard with pbpaste)"
---

# Fleet implement

Implement the spec with `/agent-fleet` as coordinator, `/implement` on each implementation track, and a cross-family adversarial audit of every track. The spec is the argument; with none, read it from the clipboard with `pbpaste`. A ticket id is fetched from the tracker and its title stated before anything else. When launched by a lead, the spec, the lead's address, and the integration coordinator's address come from the brief, and STATUS goes to the lead at each phase boundary and as `phase: handoff-written` with the path when this session's context budget sends it to a handoff.

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

- Reading a large spec, handoff, or ticket before planning: return candidate tracks with branch, tip SHA and status, write scopes, open defects per track with `file:line`, hard constraints, and the docs still to open, in ≤600 words.
- Integrating track branches, and applying the triage fixes: a write-capable subagent that commits and returns the commits.
- Repo-wide lint and full test runs: return pass or fail and only the failing excerpts.

Dispatch, end the turn, and act on the summary when it arrives.

## 1. Plan

- Split the spec into independent tracks with disjoint write scopes. Serialize anything that cannot be made disjoint.
- Assign each track an implementer and an auditor from the roster, one line of reasoning each.
- Per `/tdd`, propose the seams each track tests at, one line on what each catches and misses. Agreeing them here keeps every peer from stopping to ask separately.
- Show the user the tracks, assignments, and seams, then launch. Ask only when the split is genuinely ambiguous.
- Plan from the spec and handoffs; implementers explore their own tracks. A feasibility question goes to an Explore subagent with a ≤25-line return.

## 2. Launch

Follow the `agent-fleet` preflight from its SKILL.md and `references/cross-harness.md` → *Preflight*, *Spawn* and *Send a brief*. Open another reference only for the flag or failure in front of you; a launcher failure goes to a subagent that returns the workaround. Then spawn with one `NAME:DIR@MODEL` per peer; each opens as its own tab titled with its name. Name every peer this skill spawns for its track and role in at most three words: `<track>-impl`, `<track>-audit`, `final-review-claude`, `final-review-gpt`, `triage`, with `<track>` one or two words from the plan.

Spawn each peer just in time, when its work is ready. Launch only the implementers here: GPT implementers in one call with `--peer-harness pi`, Claude implementers in another. Each auditor spawns when its implementer replies (§3), and the final reviewers and triage peer spawn in their own phases. Auditors reply to the coordinator, which relays their findings, so a Claude implementer launched before the bridge exists needs no bridge hooks.

The current worktree's branch is the top of the gh-stack, and the fleet's work lands there. Before spawning, confirm with `gh stack view --json` that it is the topmost branch; when it sits mid-stack or outside a stack, ask the user (under a lead, the lead) before going on.

Peers writing to the same checkout each get their own worktree and a track branch cut from that top, initialized the way the project's `AGENTS.md` says. Track branches are scaffolding: they merge back into the top in §4 and stay out of the stack, with no PRs of their own.

Setting up a worktree is slow, so reuse one wherever you can:

- Only writers get a worktree. Auditors, final reviewers and triage are read-only and work in the implementer's worktree or the current one.
- Before adding a worktree, list them with `git worktree list`. Reuse one that is clean (`git status --porcelain` is empty), has no live peer in it, and whose branch is already merged into the top. Cut the track branch in place with `git switch -C <track branch> <top>`.
- Rerun the project's install only when the dependency manifests or lockfile differ between the worktree's old HEAD and the top (`git diff --quiet <old HEAD> <top> -- <lockfile>`). Otherwise the installed dependencies are still valid.
- Create a new worktree only when none qualifies, and leave every worktree in place after the run for the next one to reuse.

## 3. Brief

Implementer brief:

- The track's extract, inlined: scope, acceptance, and the grill decisions that bind it, with the plan path for reference only.
- Directory, branch, and exact write scope.
- The agreed seams.
- Discovery and design go to an Explore subagent.
- Context budget: when it writes its handoff, it asks the coordinator to respawn it.
- Run `/implement`: tdd, typecheck and single-file tests as it goes, `/review-code quick`, fix Blocker and Major findings, commit.
- Reply format: commits, files touched, test results, anything skipped or blocked.
- The coordinator's literal return address from `peer-addr.py --me`: `uds:` for a Claude peer, `pi:` for a GPT peer, which replies with `bridge.ts send`.

When an implementer replies, spawn its auditor with the §2 spawn command (`--peer-harness pi` for a GPT auditor) and send it the auditor brief:

- The spec slice and the commit range.
- The intent question: did the diff deliver what the spec promised, what did it invent, what did it skip.
- Read-only. Findings ranked Blocker, Major, Minor with `file:line`. Reply once, ≤600 words.

Confirmed Blocker and Major findings go back to the implementer for one fix round. After that the coordinator decides and records the decision in the report.

Send the briefs, re-arm `bridge.ts wait` in the background while a GPT peer is live, and end the turn. Replies wake the coordinator. A send receipt means accepted, so a peer that has not replied is still working.

## 4. Integrate

Done here means every track is implemented, audited, and integrated:

1. A subagent integrates the track branches onto the stack top, the current branch.
2. A subagent runs the project's repo-wide lint and full test suite.
3. When the brief names an integration coordinator, stage (§4a) before the teardown.
4. Tear down the implementer and auditor peers per `agent-fleet`: run the printed `hc kill <t> && hc rm <t>` for their terminals, confirm with `peer-addr.py`. Leave the bridge running; the final reviewers need it.

## 4a. Stage

The integration coordinator named in the brief merges the tips into a live environment and reports what it observed. Messages follow `~/.agents/skills/fleet-lead/references/protocol.md`.

- Send STAGE: mode, base, the tips table, the diff range, reload, migration, browser target, caveats, and the known-failures path. End the turn; the integration coordinator replies ACK, then RESULT or DEFECT.
- Implementers stay alive until RESULT. A DEFECT goes to its authoring implementer for one fix round, then a new STAGE with `supersedes=<old id>`; rewritten SHAs make it `mode: rebuild`. After that round the coordinator decides and records the decision in the report.
- A command the brief marks as gated goes to the lead as GATE; the lead answers GATE-DONE or GATE-DENIED.
- After triage, send one more STAGE when the fixes touch served code; lint and tests cover the rest.

## 5. Open the PR

The PR goes up before the final review, so CI runs alongside it. A subagent loads `gh-stack` and `pr-template`, submits the stack from the current worktree with its branch as the top, and returns the PR URLs.

Under a lead, this is the push gate: send STATUS `phase: PR` and start §6 in the same turn. On GO-PUSH, dispatch the PR subagent; on GO-HOLD the branches stay local.

## 6. Final review

The final review runs once per implementation. It is slow and expensive, so never rerun it: not after the triage fixes, not after a failing test, not to confirm a fix. Fixes made after it are checked by lint and tests alone.

Two fresh peers review the combined diff with `deep-review-code`, one from each family:

- `opus` reviewer.
- `gpt-6.1-sol:high` reviewer, launched first with `--peer-harness pi`.

Pick the mode once and give both the same one. `full` when the diff is large, crosses module boundaries, or touches auth, data, migrations, or a public API. `quick` otherwise. State the choice and the reason in one line.

Reviewer brief:

- Read `~/.agents/skills/deep-review-code/SKILL.md` and follow the `<mode>` mode. Reading the file works for both harnesses; the skill cannot be invoked by a peer.
- The resolved scope, verbatim: `git diff <merge-base>...HEAD` at head `<sha>`, and the spec path for the intent lens.
- Read-only. Write the full report to `<scratchpad>/final-review-<family>.md` and reply with its path and a 10-line verdict.

While they run, the coordinator waits for the two paths; the reports go to triage by path and stay unread here.

## 7. Triage

When both reports are in, spawn one triage peer: `gpt-6-astra:high` when most of the implementation came from Claude peers, `fable` when it came from GPT peers. Send it the spec, the scope, and both report paths.

Triage brief:

- Merge findings that share a root cause.
- Mark each finding **fix** or **drop**. Fix a defect a user or caller would hit, or a spec promise the diff does not keep. Drop speculative hardening, new abstractions or configuration, tests for states the code cannot reach, and style the repo's standards do not require.
- For each fix, name the smallest change at `file:line`. For each drop, one line of why.
- Read-only. Reply once.

A subagent applies the fixes, reruns lint and the full test suite, and pushes the fixes to the open PR. Do not send the fixes back to the reviewers or the triage peer.

## 8. Finish

1. Report the PR URLs (or the local branches on GO-HOLD), what landed, what was skipped, which commits came from which track, each auditor's verdict, both final review verdicts, and the triage list with what was fixed and what was dropped.
2. Tear down the final review and triage peers per `agent-fleet`, stop the bridge last, and confirm with `peer-addr.py`. Keep them only when the user asked. Then mark the coordinator tab `-done` per `agent-fleet`.
3. Under a lead: reply DONE with the report.
