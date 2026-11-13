---
name: fleet-lead
description: Run a queue of specs through fleet-implement coordinators against one live integration environment at the company, from the session Jason types into.
disable-model-invocation: true
argument-hint: "<spec|handoff path>…"
---

# Fleet lead

Run the specs or handoffs given as arguments, one impl coordinator at a time, against one long-lived integration coordinator that merges, serves, and observes each stage. This session is the lead: it plans once, spawns, routes, runs gated commands on Jason's yes, chains the queue, and finishes. It writes no checkout and messages only its two coordinators. Run it in a tab of the `jason-ai-research` Herdr space.

Message formats: [references/protocol.md](references/protocol.md). The integration coordinator's brief: [references/integration.md](references/integration.md).

## Roles

- **Lead** (this session): ledger, worktree and services lifecycle, gates, priority, chaining, teardown of its coordinators.
- **integration-coordinator** (`opus`, a tab on the integration worktree): single writer of the integration branch; brings services up with `teamqa`; answers every STAGE with RESULT or DEFECT.
- **impl-<slug>** (`opus`, a tab in `jason-ai-research`): runs `fleet-implement` on one spec, stages through the integration coordinator, pushes only on GO-PUSH.

## 1. Plan screen

A background subagent reads every argument and returns, in ≤40 lines: ticket, tracks with write scopes, stack tips (branch, sha, worktree), standing fix branches named, migrations or workers or Slack touched, and `git diff --name-only <base>...<tip> | cut -d/ -f1-2 | sort -u` per stack. Then show Jason one screen and wait for "go" or edits:

- Queue order, one line per spec, each with stage **yes** or **no** (footer, docs, or tests-only work needs none).
- Service set from the touched directories: `web/ai` or `packages/ig-types` API-only → `ai`; `web/frontend` → `fe` against a remote stage, or `ai,fe` / `all` per data target; backend or mixed → `all`.
- Data target: local by default; shared **dev-11** when the scope touches schedules, workers, or Slack.
- Current holders of `:3000`, `:3001`, `:13557`: `lsof -nP -iTCP:3000,3001,13557 -sTCP:LISTEN` then `lsof -a -p <pid> -d cwd -Fn`.
- Standing fix branches to merge into the integration branch.
- Known failures: `known-failures.md` beside the ledger, started from the failing tests and lint the digest found.
- Models per role.
- Standing decisions: restart own services **yes**; reset or rebuild own integration branch **yes**; shared-DB migration **ask**; stopping a server Jason started **ask**; widening the service set **ask**; push and PR **ask**.

Create the ledger at `$AI_NOTEBOOK_PATH/plans/<stamp>-<ticket>-fleet-lead/ledger.md` with the notebook skill and write Jason's answers verbatim with timestamps. The screen appears once per run; later questions are gates.

## 2. Worktree

```bash
git worktree add ~/.herdr/worktrees/acme/<ticket>-integration -b jason/chore/<ticket>-integration <stack tip>   # or reuse the existing one
cd ~/.herdr/worktrees/acme/<ticket>-integration
direnv allow && bash scripts/symlink-worktree.sh && pnpm install --frozen-lockfile --ignore-scripts && moon run :generate   # what igwt does
git merge --no-edit <standing fix branches>
```

Data target dev-11: write `~/.team-qa/services.json` so the `ai` service runs `node cli/bin/aicli.js dev --node-backend local --ai-db dev-11 --resources dev-11` with an empty `before` list, so no shared migration runs on its own; keep the previous file to restore at Finish.

## 3. Spawn

Two `spawn-fleet.py` calls from `~/.claude/skills/agent-fleet/scripts/`, both `--permission-mode auto`, with the names fixed here for the whole run:

```bash
python3 spawn-fleet.py --permission-mode auto integration-coordinator:<integration worktree>@opus
python3 spawn-fleet.py --permission-mode auto impl-<slug>:<this checkout>@opus
```

Roster to the ledger: name, `uds:` address, pid, hc terminal id, role. The lead's own address comes from `peer-addr.py --me`.

## 4. Brief

Send with `SendMessage` to the literal `uds:` addresses.

Integration coordinator: "Read `~/.claude/skills/fleet-lead/references/integration.md` and follow it." Plus: the ledger path, the service set, the data target, the standing decisions verbatim, the lead's and impl coordinator's addresses, the known-failures path, the reply format from `protocol.md`.

Impl coordinator: "Read `~/.claude/skills/fleet-implement/SKILL.md` and follow it on `<spec path>`." Plus: the integration coordinator's and lead's addresses, the stage decision from the plan screen, the known-failures path, "push and open PRs only on GO-PUSH from the lead, then reply DONE", and the lead's address for STATUS lines.

Then end the turn. Replies wake the lead.

## 5. Route

- **GATE**: ask Jason one numbered line with the command, `cwd`, and blast radius. On yes, run the command here and reply GATE-DONE with the output tail; otherwise GATE-DENIED with Jason's words. Log both in the ledger.
- **PRIORITY**: Jason's words verbatim with a timestamp, plus the preset `demo` or `checkpoint` where one fits, to both coordinators.
- **STATUS**: on Jason's ask, answer from the roster and the ledger tail. Rows from STATUS, STAGE, RESULT, and DEFECT go to the ledger with their superseded-by links. STATUS `phase: PR` from an impl coordinator is the push gate: ask Jason one line, then send GO-PUSH on yes or GO-HOLD otherwise; the coordinator replies DONE after its final review and triage.
- **SAID**: log it; act on it only where it changes a gate or the priority.

Respawn: a coordinator that sends STATUS `phase: handoff-written` (its context budget is spent) is spawned again as `<name>-2` with its handoff and the ledger path in the brief; the lead sends ROSTER with the new address to the other coordinator, then tears the old one down.

## 6. Chain

On DONE: tear the impl coordinator down per `agent-fleet` (`hc kill <t> && hc rm <t>`, confirm with `peer-addr.py`). With specs left in the queue, spawn the next `impl-<slug>` as in §3, brief it as in §4 with the same integration coordinator address, and send ROSTER to the integration coordinator.

## 7. Finish

On DONE with the queue empty: tear down the integration coordinator, run `teamqa down` from the integration worktree, confirm with `peer-addr.py`, restore `~/.team-qa/services.json` when §2 wrote it, and close the ledger with the PR URLs and any branches held local. The worktree and branch stay.
