---
name: implement-prd
description: Work through a PRD's issues in dependency order using YAML workflow states, AFK/HITL routing, and proper status tracking.
---

# Work on PRD

Work through a PRD's implementation issues in dependency order.

## Input

The user provides a project slug or path (e.g., `auth` or `./plans/auth/`).

If none provided, ask: "Which PRD should I work on? (project slug or path)"

## Workflow states

```
backlog → todo → in-progress → in-review → qa → done
                      ↕
                   blocked
```

## Process

### 1. Read the PRD and issues

Read `./plans/{slug}/prd.yaml` and all files in `./plans/{slug}/issues/`.

If no issue files exist, tell the user: "This PRD has no implementation issues. Run `/planning-prd-to-issues` first."

### 2. Build the execution queue

Build the queue from YAML fields, not prose:

- `blocked_by` dependencies
- `status`
- `assignee`
- `priority`
- `labels` (AFK / HITL)
- `points`

Routing rules:

- determine agent routing from labels: **AFK** (autonomous) and **HITL** (needs human)
- prefer issues already in **todo**
- do not auto-pick issues in **blocked** unless the blocker is clearly resolved
- if none are in todo, choose the highest-priority unblocked **AFK** issue in **backlog**, move it to todo, then start it
- if a previously blocked issue becomes unblocked, move it to **todo** before resuming
- skip issues assigned to someone else unless the user says to take them
- read `blocked_by` fields — do not parse prose for dependency info

Present the plan as a numbered list showing:

- issue ID and title
- current status
- routing label (AFK / HITL)
- blockers
- points
- why it is next

### 3. Work through issues

Process issues in dependency order using the `implement-issue` workflow.

**AFK issues**: proceed automatically, then move to the next ready issue.

**HITL issues**: stop and explain the specific decision or input needed. Wait for the user's response.

**Blocked issues**: set `status: blocked` in the YAML, record the reason in `notes`, move to the next ready issue. Once the blocker clears, set `status: todo` before resuming.

### 4. Status report

After all ready issues are processed, print a summary:

```text
PRD: <project name>
Done:        <count>
In Review:   <count>
Blocked:     <count> (<issue IDs>)
QA:          <count>
Remaining:   <count> (<issue list>)
Points done: <sum> / <total>
PRs:         <list of PR URLs>
```

Update `prd.yaml` status to `complete` when all issues are done.
