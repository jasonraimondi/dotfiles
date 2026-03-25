---
name: implement-issue
description: Implement one or more Linear issues end-to-end using native Linear workflow, RAL lanes, and GitHub↔Linear linking.
---

# Work on Issue

Implement one or more Linear issues end-to-end. Linear fields and relationships are the source of truth for workflow; markdown is for human context only.

## Input

The user provides one or more Linear issue identifiers or URLs.

If none is provided, ask: "Which Linear issue(s) should I work on?"

## RAL workflow lanes

Use the RAL team's current lanes:

- **Backlog** = planned or not currently actionable
- **Todo** = ready to pick up
- **In Progress** = actively being implemented
- **Blocked** = work started but is waiting on an external dependency, decision, or unblock
- **In Review** = PR is open or awaiting review
- **QA** = merged and awaiting verification / validation
- **Done** = complete
- **Canceled / Duplicate** = stop

## Process (per issue)

### 1. Fetch the issue

Fetch the issue from Linear. Read:

- description and acceptance criteria
- native dependencies
- current state
- assignee
- labels
- project / cycle / priority

If the issue has unresolved blockers, report them and skip it.
If the issue is already in **Blocked**, confirm the blocker is actually cleared before resuming work.
If the issue is assigned to someone else, ask before taking it over.

### 2. Move the issue into the active queue

If the issue is in **Backlog** and you are about to start it, move it to **Todo**.
If the issue is in **Blocked** and the blocker is cleared, move it back to **Todo**.
When implementation starts, move it to **In Progress**.

### 3. Branch setup

Check if the current branch is already dedicated to this issue or its parent PRD / project context.

- If yes: stay on the current branch.
- If no: create a new branch using `<user>/<issue-id>-<short-slug>`.

### 4. Explore the codebase

Use the available tools to understand:

- modules mentioned in the issue
- adjacent code paths and existing patterns
- existing tests for similar behavior

### 5. Implement

Choose the approach that fits:

- **TDD** when acceptance criteria are clear and behavioral
- **Implement-first** when the work is exploratory, UI-heavy, or the acceptance criteria need discovery

Rules:

- follow existing patterns and conventions
- use `moon run <project>:lint` to validate changes
- use `moon run <project>:test` after implementation
- fix lint and test failures before moving on

### 6. Commit

Create meaningful commits as you work. Use conventional commit format: `type(scope): description`.

### 7. Open PR

Once implementation is complete and tests pass:

1. Push the branch with `-u`
2. Create a PR with the Linear issue ID in the branch name, title, and body so GitHub↔Linear linking works automatically
3. Include a concise test plan in the PR body
4. Add a Linear comment only if the PR does not auto-link or if extra handoff context is useful

### 8. Update Linear state

Use native RAL lanes, not hardcoded generic states:

- when the PR is open, move the issue to **In Review**
- after merge, move the issue to **QA** if manual verification or stakeholder validation is still needed
- move the issue to **Done** only after the work is actually complete for the team's workflow
- if the issue becomes blocked after work has started, move it to **Blocked** and add the native dependency and/or concise blocker comment
- once the blocker is cleared, move it back to **Todo** or **In Progress** as appropriate

### 9. Next issue

If there are more issues to work, proceed to the next one.

- stay on the same branch only when that matches the existing PRD / project workflow
- otherwise create a new branch per issue

## Multiple issues

When given multiple issues, work them sequentially in the chosen order. If any issue is blocked, skip it and report it at the end.
