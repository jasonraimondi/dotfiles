---
name: implement-prd
description: Work through a PRD project or umbrella issue in dependency order using native Linear relationships, RAL workflow lanes, and AFK/HITL labels.
---

# Work on PRD

Work through a PRD's implementation issues in Linear-native order.

## Input

The user provides a Linear **project** identifier or URL. If they only have a PRD umbrella issue, accept that too.

If none is provided, ask: "Which PRD should I work on? (Linear project or umbrella issue URL/ID)"

## RAL workflow lanes

Use the RAL team's current lanes rather than inventing your own:

- **Backlog** = planned or not currently actionable
- **Todo** = ready to pick up
- **In Progress** = actively being implemented
- **Blocked** = work started but is waiting on an external dependency, decision, or unblock
- **In Review** = PR is open or awaiting review
- **QA** = merged and awaiting verification / validation
- **Done** = complete
- **Canceled / Duplicate** = do not execute

## Process

### 1. Fetch the PRD container and issues

If given a project:

- fetch the project and its open implementation issues
- exclude the umbrella PRD issue itself and any obvious planning-only meta issues from the executable queue
- if the project has an umbrella issue, use it to understand hierarchy, but trust native project and dependency data first

If given an umbrella issue:

- fetch the issue, its project if any, and its native sub-issues

If no implementation issues exist, tell the user: "This PRD has no implementation issues. Run `/planning-prd-to-issues` first."

### 2. Build the execution queue

Build the queue from native Linear fields, not markdown:

- blocked-by dependencies
- state
- assignee
- priority
- cycle / target date
- project ordering
- AFK / HITL labels

Routing rules:

- determine agent routing from labels, preferably **AFK** and **HITL**
- prefer ready issues already in **Todo**
- do not auto-pick issues already in **Blocked** unless the blocker is clearly resolved
- if none are in Todo, choose the highest-priority unblocked **AFK** issue in **Backlog**, move it to Todo, then start it
- if a previously blocked issue becomes truly unblocked, move it back to **Todo** before resuming
- skip issues assigned to someone else unless the user explicitly says to take them over
- never parse a `Blocked by` markdown section; use native dependencies only

Present the plan to the user as a numbered list showing:

- issue identifier and title
- current state
- routing label (AFK / HITL)
- blockers
- why it is next

### 3. Work through issues

Process issues in dependency order using the `implement-issue` skill.

**AFK issues**:

- proceed automatically
- after each issue, post a concise progress note on the PRD project or umbrella issue
- then move to the next ready issue

**HITL issues**:

- stop and explain the specific decision or input needed
- wait for the user's response before proceeding

**Blocked issues**:

- if work is waiting on an external dependency, decision, or unblock, move the issue to **Blocked** and record the blocker natively in Linear
- once the blocker is cleared, move the issue back to **Todo** before resuming
- do not rewrite blockers into markdown

### 4. Status report

After all ready issues are processed, print a summary:

```text
PRD: <project or umbrella title>
Done: <count>
In Review: <count>
Blocked: <count>
QA: <count>
Remaining: <count and issue list>
PRs: <list of PR URLs>
```
