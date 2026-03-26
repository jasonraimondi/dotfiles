---
name: implement-issue
description: Implement one or more plan issues end-to-end with proper branching, testing, and status tracking via YAML workflow states. When issues are synced to Linear, updates both local YAML and Linear.
allowed-tools: Bash(linear:*), Bash(jq:*)
---

# Work on Issue

Implement one or more issues from a plan end-to-end. YAML fields are the source of truth for workflow; prose is for human context only.

## Input

The user provides one or more issue references:

- file path: `./plans/auth/issues/1-setup-middleware.yaml`
- shorthand: `auth#1` (project slug + issue ID)

If none provided, ask: "Which issue(s) should I work on?"

## Workflow states

```
backlog → todo → in-progress → in-review → qa → done
                      ↕
                   blocked
```

## Process (per issue)

### 1. Read the issue

Read the issue YAML file. Check:

- acceptance criteria and steps
- blocked_by — read those issues too, confirm they are in done or canceled
- current status
- assignee
- labels
- priority
- track
- tdd / headed flags

If unresolved blockers exist (blocked_by issues not in done/canceled), report them and skip.
If the issue is blocked, confirm the blocker is cleared before resuming.
If assigned to someone else, ask before taking it.

### 2. Update status

Update the YAML file:

- backlog → todo (when about to start)
- blocked → todo (when blocker is cleared)
- todo → in-progress (when implementation starts)
- always update the `updated` date on status changes

**Linear sync**: if the issue has `linear_id`, also update the Linear issue state:

```bash
linear issue update {linear_id} --state "{new_status}"
```

### 3. Branch setup

Check if the current branch is already dedicated to this issue or its parent project.

- If yes: stay on the current branch
- If no: create a new branch using `<user>/<project-slug>/<issue-id>-<issue-slug>`

### 4. Explore the codebase

Understand:

- modules mentioned in the issue steps
- adjacent code paths and existing patterns
- existing tests for similar behavior

### 5. Implement

#### When `steps` exist

Follow the steps in order. Each step provides a `Target — required behavior` pair that specifies where to work and what the behavior should be.

- **`tdd: true`**: invoke the `testing-tdd` skill. Use the steps to determine test boundaries — write tests for the behavior described in each step, then implement to make them pass.
- **`headed: true`**: invoke the `tooling-agent-browser` skill for visual verification. Steps with verification targets (e.g., "verify toast appears") define what to check in the browser.
- **Both flags**: TDD for logic, browser verification for visual outcomes.
- **Neither flag**: implement steps directly, verify with lint and existing test suite.

#### When steps are absent (legacy issues)

Fall back to acceptance criteria:

- **TDD** when acceptance criteria are clear and behavioral
- **Implement-first** when the work is exploratory, UI-heavy, or requires discovery

#### General rules

- follow existing patterns and conventions
- lint and test after implementation
- fix lint and test failures before moving on

### 6. Commit

Create meaningful commits using conventional commit format: `type(scope): description`.

### 7. Open PR

Once implementation is complete and tests pass:

1. Push the branch with `-u`
2. Create a PR with the issue reference in the title and body
3. Include a concise test plan in the PR body

### 8. Update issue YAML

Update the issue file:

- set `branch` to the branch name
- set `pr` to the PR URL
- set `status: in-review`
- after merge: `status: qa` if verification needed, or `status: done`
- if blocked after starting: `status: blocked`, explain in `notes`
- always update `updated` date

**Linear sync**: if the issue has `linear_id`, also push these changes to Linear:

```bash
# Update status
linear issue update {linear_id} --state "{new_status}"
```

Attach the PR to the Linear issue if one was created — use `linear api` with a GraphQL mutation to create an attachment:

```bash
linear api --method POST --body '{"query":"mutation{attachmentCreate(input:{issueId:\"{linear_id}\",url:\"{pr_url}\",title:\"Pull Request\"}){success}}"}'
```

### 9. Next issue

If there are more issues, proceed to the next one.

- stay on the same branch only when working on tightly coupled issues from the same project
- otherwise create a new branch per issue
- if any issue is blocked, skip it and report at the end

## Linear sync

When a plan has been synced to Linear (issues have a `linear_id` field), update both local YAML **and** Linear on every status change. Local YAML is always updated first — Linear updates are best-effort. If a Linear update fails, log the failure and continue (do not block implementation).

Check for `linear_id` once when reading the issue (step 1). If present, all status transitions in steps 2 and 8 push to Linear.

## Multiple issues

When given multiple issues, work them sequentially. If any issue is blocked, skip it and report at the end.
