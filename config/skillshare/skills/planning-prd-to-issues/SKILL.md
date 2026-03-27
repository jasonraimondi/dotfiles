---
name: planning-prd-to-issues
description: Break a PRD into independently grabbable issues using thin vertical slices, writing structured YAML files to ./plans/{slug}/issues/. Use when user says "break this down", "create issues", "decompose the PRD", or wants to convert a PRD into actionable work items.
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
track: rules       # intent | experience | data | rules | resilience
status: backlog    # backlog | todo | in-progress | blocked | in-review | qa | done | canceled
priority: high     # urgent | high | medium | low
points: 3          # fibonacci: 1, 2, 3 (max)
labels:
  - AFK            # AFK = autonomous, HITL = needs human input
assignee: null
blocked_by: []     # issue IDs within this project
blocking: []       # issue IDs within this project
branch: null
pr: null
linear_id: null       # Linear issue identifier (e.g., RAL-123), set by sync
created: YYYY-MM-DD
updated: YYYY-MM-DD
tdd: true          # optional — issue has testable behavior
headed: false      # optional — issue requires browser-visible verification

outcome: |
  What this slice delivers.

scope: |
  What is included. Keep it narrow.

acceptance_criteria:
  - "Criterion 1"
  - "Criterion 2"

steps:
  - "Target — required behavior"
  - "Target — required behavior"

use_cases:
  - UC-1

notes: |
  Relevant context, constraints, or prior art.
```

### Field reference

#### `track`

Classifies the issue's primary concern. Every issue gets exactly one track.

| Track | When to use |
|-------|-------------|
| `intent` | API endpoints, service wiring, core business flow |
| `experience` | UI components, navigation, visual feedback, user-facing interactions |
| `data` | Schema, migrations, CRUD operations, entity lifecycle, queries |
| `rules` | Authorization, validation, business rules, permission boundaries |
| `resilience` | Error handling, retry logic, failure modes, rate limiting, external dependency fallbacks |

#### `tdd`

Mark `tdd: true` when the issue has testable behavior:

- `rules` issues — almost always
- `data` issues — CRUD, cascade, lifecycle behavior
- `intent` issues with API/service behavior
- `resilience` issues — error handling, retry logic

Skip for pure UI/styling, configuration-only, or wiring-only issues.

When `tdd: true`, the implementation agent invokes the `testing-tdd` skill and decides the RED→GREEN structure based on the steps.

#### `headed`

Mark `headed: true` when correctness requires browser-visible verification:

- `experience` issues — almost always
- Any issue where visual state, layout, or interaction must be verified

When `headed: true`, include visual verification targets in steps:
```
Route /dashboard — verify search input renders and filters list on keystrokes
```

The implementation agent invokes the `tooling-agent-browser` skill.

#### `steps`

Ordered implementation actions following the `Target — required behavior` pattern:

```yaml
steps:
  - "Route /auth/login — reject expired tokens with 401"
  - "Token refresh endpoint — issue new token when refresh token is valid and not revoked"
  - "Auth middleware — attach user context to request on valid token"
```

Steps tell the implementation agent **how** to build the issue. Acceptance criteria tell reviewers **what** to verify.

Step count scales with issue complexity — a 1-point issue might have 2 steps, a 3-point issue might have 5-6. Every step must include location context (route, file path, service name, component).

#### `points`

Fibonacci scale: 1, 2, 3. **Maximum 3 points per issue.** Issues estimated at 5+ points must be split into smaller slices. If you cannot find a natural seam to split on, the issue scope is too broad — narrow the outcome.

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

### 2. Explore the codebase

Understand the current system, likely slice boundaries, and existing patterns. This grounds track assignment and step specificity in reality.

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
- **maximum 3 points per issue** — split anything larger
- assign a `track` to every issue based on its primary concern

#### Track coverage check

After drafting all slices, verify track coverage against the PRD:

- Feature touching data? → needs `data` track issues
- Feature with authorization/validation? → needs `rules` track issues
- Feature with UI? → needs `experience` track issues
- Feature with external dependencies or failure modes? → needs `resilience` track issues

Missing tracks are the highest-signal gap. Flag them to the user.

### 4. Write steps for each issue

For each issue, write concrete implementation steps using the `Target — required behavior` pattern.

Rules:

- every step includes location context (route, file, service, component)
- no vague language: "handle errors appropriately", "set up properly", "add necessary validation"
- `headed: true` steps include visual verification targets
- steps are ordered by implementation sequence

### 5. Review the breakdown with the user

Present the proposed breakdown as a numbered list. For each slice:

- **Title** and **track**
- **Routing label**: AFK / HITL
- **Points estimate** (max 3)
- **Priority**: urgent / high / medium / low
- **tdd** / **headed** flags
- **Initial status**: backlog or todo
- **Blocked by**: which other slices must complete first
- **Use cases covered**: which PRD use cases this addresses
- **Acceptance criteria**: 2-4 bullets
- **Steps**: implementation actions

Ask the user:

- Does the granularity feel right?
- Are the dependencies correct?
- Should any slices be merged or split?
- Are the right slices marked AFK vs HITL?
- Which slices should start in todo vs stay in backlog?
- Is the track coverage complete?

Iterate until the user approves.

### 6. Write the issue files

Create `./plans/{slug}/issues/` and write one YAML file per approved slice.

Rules:

- `blocked_by` and `blocking` must be kept in sync across issues (if issue 3 is blocked by issue 1, then issue 1 must list 3 in its `blocking`)
- IDs are sequential integers starting at 1
- filename is `{id}-{slug}.yaml`
- structure lives in YAML fields — do not duplicate dependencies or status in prose

### 7. Update the PRD status

Set `status: active` and update the `updated` date in `prd.yaml`.

### 8. Confirm the result

After creation, share:

- the path to the issues directory
- issue IDs in dependency order
- track coverage summary (which tracks are represented)
- which issues are in todo (ready now)
- which issues are in backlog (waiting)
- total points estimate

## Example

```yaml
id: 3
slug: role-change-authorization
name: "Implement role-change authorization boundaries"
track: rules
status: backlog
priority: high
points: 3
labels:
  - AFK
assignee: null
blocked_by: [1]
blocking: [5]
branch: null
pr: null
linear_id: null
created: 2026-03-25
updated: 2026-03-25
tdd: true

outcome: |
  Role changes are enforced server-side with proper permission boundaries.

scope: |
  Authorization logic for role mutations. Does not include UI for role management.

acceptance_criteria:
  - "Admin cannot promote to owner"
  - "Sole owner cannot self-demote"
  - "Admin can promote member to admin"
  - "Non-admin role change attempts return 403"

steps:
  - "Role change handler — reject admin-to-owner promotion with 403 'Insufficient permissions'"
  - "Owner demotion guard — prevent sole owner self-demotion with 'Cannot demote sole owner'"
  - "Permission check — allow admin to promote member to admin"
  - "Authorization middleware — return 403 for non-admin role change attempts"

use_cases:
  - UC-3

notes: |
  Existing auth middleware handles authentication. This issue adds role-specific authorization on top.
```
