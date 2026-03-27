---
name: planning-write-an-issue
description: Create a single issue by interviewing the user, exploring the codebase, and writing a structured YAML issue file. Use when user says "write an issue", "create an issue", "add an issue", or wants to define a single work item — either standalone or inside an existing plan.
---

# Write an Issue

Create a single implementation issue as a structured YAML file.

## Placement

An issue can live in two places:

1. **Inside a plan**: `./plans/{slug}/issues/{id}-{issue-slug}.yaml` — when a PRD already exists
2. **Standalone**: `./issues/{issue-slug}.yaml` — for one-off work items without a parent PRD

Ask the user which they want. If a plan exists, read the PRD to ground the issue in project context.

## Process

### 1. Clarify the work

Ask the user for:

- what needs to happen
- why it matters (bug? feature? tech debt?)
- expected outcome when done
- known constraints or blockers

### 2. Explore the codebase

Investigate the areas of code the issue will touch. Ground the issue's steps and scope in the current system — not in assumptions.

### 3. Interview to convergence

Resolve with the user:

- the narrowest useful scope (thin vertical slice)
- acceptance criteria — what "done" looks like
- track classification
- whether TDD or headed verification applies
- dependencies on other issues (if inside a plan)
- AFK vs HITL routing

Keep the issue to **3 points maximum**. If it's bigger, recommend splitting and offer to write multiple issues.

### 4. Draft the issue

Write the issue YAML using this schema:

```yaml
id: 1
slug: issue-slug
name: "Short descriptive title"
track: rules       # intent | experience | data | rules | resilience
status: backlog    # backlog | todo | in-progress | blocked | in-review | qa | done | canceled
priority: high     # urgent | high | medium | low
points: 2          # fibonacci: 1, 2, 3 (max)
labels:
  - AFK            # AFK = autonomous, HITL = needs human input
assignee: null
blocked_by: []     # issue IDs within this project
blocking: []       # issue IDs within this project
branch: null
pr: null
linear_id: null    # Linear issue identifier (e.g., RAL-123), set by sync
created: YYYY-MM-DD
updated: YYYY-MM-DD
tdd: true          # optional — issue has testable behavior
headed: false      # optional — issue requires browser-visible verification

outcome: |
  What this issue delivers.

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

### Field guidance

#### `track`

| Track | When to use |
|-------|-------------|
| `intent` | API endpoints, service wiring, core business flow |
| `experience` | UI components, navigation, visual feedback, user-facing interactions |
| `data` | Schema, migrations, CRUD operations, entity lifecycle, queries |
| `rules` | Authorization, validation, business rules, permission boundaries |
| `resilience` | Error handling, retry logic, failure modes, rate limiting, external dependency fallbacks |

#### `tdd`

Mark `tdd: true` when the issue has testable behavior — `rules`, `data`, `intent` with API behavior, `resilience`. Skip for pure UI/styling or configuration-only work.

#### `headed`

Mark `headed: true` when correctness requires browser-visible verification. Include visual verification targets in steps when set.

#### `steps`

Ordered implementation actions using `Target — required behavior`:

```yaml
steps:
  - "Route /auth/login — reject expired tokens with 401"
  - "Auth middleware — attach user context to request on valid token"
```

Every step includes location context (route, file, service, component). No vague language.

#### `points`

Fibonacci: 1, 2, 3. **Maximum 3 points.** If the issue estimates higher, split it.

### 5. Review with the user

Present the drafted issue. Ask:

- Is the scope narrow enough?
- Are the acceptance criteria verifiable?
- Are the steps concrete and ordered correctly?
- Is the track/tdd/headed classification right?

Iterate until approved.

### 6. Write the file

**Inside a plan**: read existing issues to determine the next ID. Write `./plans/{slug}/issues/{id}-{issue-slug}.yaml`. Update `blocked_by`/`blocking` in sibling issues if dependencies were added.

**Standalone**: write `./issues/{issue-slug}.yaml`. Omit `id`, `blocked_by`, `blocking`, and `use_cases` fields.

Rules:

- set `created` and `updated` to today's date
- `blocked_by` and `blocking` must be kept in sync across issues
- filename uses the issue slug

### 7. Hand off cleanly

After creation, share:

- the file path to the issue
- whether it's ready to implement (`/implement-issue`) or still blocked
- a one-line summary of what the issue delivers
