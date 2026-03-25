---
name: planning-prd-to-issues
description: Break a PRD into independently grabbable issues using thin vertical slices, writing structured YAML files to ./plans/{slug}/issues/.
---

# PRD to Issues

Break a PRD into implementation issues stored as YAML files.

## Plan structure

Issues live alongside their PRD:

```
./plans/{project-slug}/
  prd.yaml
  issues/
    1-setup-auth-middleware.yaml
    2-add-token-refresh.yaml
    ...
```

Filenames follow `{id}-{slug}.yaml`. IDs are integers starting at 1, assigned in creation order.

## Issue schema

```yaml
id: 1
slug: setup-auth-middleware
name: "Set up authentication middleware"
status: backlog  # backlog | todo | in-progress | blocked | in-review | qa | done | canceled
priority: high   # urgent | high | medium | low
points: 3        # fibonacci: 1, 2, 3, 5, 8, 13
labels:
  - AFK          # AFK = autonomous, HITL = needs human input
assignee: null
blocked_by: []   # issue IDs within this project
blocking: []     # issue IDs within this project
branch: null
pr: null
created: YYYY-MM-DD
updated: YYYY-MM-DD

outcome: |
  What this slice delivers.

scope: |
  What is included. Keep it narrow.

acceptance_criteria:
  - "Criterion 1"
  - "Criterion 2"

use_cases:
  - UC-1

notes: |
  Relevant context, constraints, or prior art.
```

## Workflow states

```
backlog → todo → in-progress → in-review → qa → done
                      ↕
                   blocked
```

- **backlog**: planned, not yet actionable
- **todo**: ready to pick up
- **in-progress**: actively being implemented
- **blocked**: started but waiting on external dependency, decision, or unblock
- **in-review**: PR open or awaiting review
- **qa**: merged, awaiting verification
- **done**: complete
- **canceled**: stopped

## Process

### 1. Locate the PRD

Ask the user for the project slug or path. Read `./plans/{slug}/prd.yaml`.

### 2. Explore the codebase (if needed)

Understand the current system and likely slice boundaries.

### 3. Draft vertical slices

Break the PRD into **tracer-bullet** issues. Each issue is a thin vertical slice cutting through all relevant layers end-to-end — not a horizontal slice of one layer.

Labels:

- **AFK**: can be implemented and merged without human intervention
- **HITL**: requires human input — product decision, UX review, or architectural choice

Prefer AFK over HITL where possible.

Rules:

- each slice delivers a narrow but complete path through all relevant layers
- a completed slice is demoable or independently verifiable on its own
- prefer many thin slices over few thick ones
- avoid layer-only tickets unless they unlock multiple later slices or materially reduce risk

### 4. Review the breakdown with the user

Present the proposed breakdown as a numbered list. For each slice:

- **Title**
- **Routing label**: AFK / HITL
- **Points estimate**
- **Priority**: urgent / high / medium / low
- **Initial status**: backlog or todo
- **Blocked by**: which other slices must complete first
- **Use cases covered**: which PRD use cases this addresses
- **Acceptance outline**: 2-4 bullets

Ask the user:

- Does the granularity feel right?
- Are the dependencies correct?
- Should any slices be merged or split?
- Are the right slices marked AFK vs HITL?
- Which slices should start in todo vs stay in backlog?
- Are point estimates reasonable?

Iterate until the user approves.

### 5. Write the issue files

Create `./plans/{slug}/issues/` and write one YAML file per approved slice.

Rules:

- `blocked_by` and `blocking` must be kept in sync across issues (if issue 3 is blocked by issue 1, then issue 1 must list 3 in its `blocking`)
- IDs are sequential integers starting at 1
- filename is `{id}-{slug}.yaml`
- structure lives in YAML fields — do not duplicate dependencies or status in prose

### 6. Update the PRD status

Set `status: active` and update the `updated` date in `prd.yaml`.

### 7. Confirm the result

After creation, share:

- the path to the issues directory
- issue IDs in dependency order
- which issues are in todo (ready now)
- which issues are in backlog (waiting)
- total points estimate
