---
name: planning-prd
description: Create or update PRD plans for features/projects. Use when users ask to plan work, write/refine a PRD, run a planning interview, or update files in plans/. Conduct a structured interview, then output AI-executable tasks across intent/experience/data/rules/resilience as needed.
---

# PRD Planning

Plan features and projects with AI-executable tasks. Works for greenfield projects, existing codebases, and simple flat PRDs.

## Interview-first workflow (required)

1. Use `AskUserQuestion` before writing files.
2. Ask **2-4 focused questions total per round** across two layers:
   - **Product layer** (what): intent, experience, data
   - **Engineering layer** (how): rules, resilience
3. Probe edge behavior inside relevant track questions; do not postpone all edge cases to a separate round.
4. Include **"Generate plan now"** in every round, with uncovered tracks listed in the option description.
5. After each round, explicitly report covered vs uncovered tracks.
6. Stop interviewing immediately if user chooses generate now.
7. Default to **1-3 rounds max**; do not over-interview low-risk features.

If `AskUserQuestion` is unavailable in the current target/tooling, ask equivalent numbered multiple-choice questions inline and continue with the same workflow.

## Coverage tracks

- `intent` — scope, goals, boundaries, success criteria, priorities
- `experience` — UX/UI flows, pages, interactions, empty/loading/error states
- `data` — entities, schema/contracts, persistence, relationships
- `rules` — validation, permissions, auth, business logic, constraints
- `resilience` — failures, retries, degraded behavior, health checks, ops concerns

Do not force all tracks for small features. Cover only what materially affects delivery risk.

## Context detection

Before writing, read the repo's current planning files and determine context.

### Existing phased PRD files

If `plans/prd.yaml` and `plans/prd/phase-xx.yaml` exist:
- Preserve structure and history.
- Patch only relevant phase(s)/task(s).
- Prefer targeted additions over broad rewrites.
- Keep completed tasks and prior wording intact unless user asks to refactor.

### Existing non-phased planning files

- Follow local conventions.
- Keep interview depth and step quality high.
- Migrate formats only if user requests migration.

### No planning files (existing project)

- Ask whether to create a minimal feature plan in phased format or bootstrap a full project plan.
- Default to a minimal feature plan if user does not care.

### Greenfield project

Create/maintain:
- `plans/prd.yaml`
- `plans/prd/shared.yaml`
- `plans/prd/phase-xx.yaml`
- `plans/research.md` (index-level pointer)
- `plans/progress.md`

## Plan sizing

Choose the smallest useful plan:

| Context | Small | Medium | Large |
|---------|-------|--------|-------|
| Feature | 1 phase, 2-5 tasks | 2 phases, 3-7 tasks | 3+ phases |
| Project | 1-2 phases | 3-6 phases | 7+ phases |

If uncertain, ask one sizing question and default to the leaner option.

## Phase sequencing guidance (greenfield)

Use coherent delivery slices:
1. Foundation/scaffolding/tooling
2. Core data/domain/rules
3. User-facing experience and flows
4. Hardening/resilience/operations

Adapt order to project-specific priorities.

## AI-executable task quality bar (required)

Every task must be structured so an implementation agent can pick it up with minimal interpretation.

For each task:
- One clear outcome (no mixed goals in a single task).
- Correct `track` classification.
- `description` starts with a strong verb (`Build`, `Implement`, `Configure`, `Create`, `Define`, `Write`, `Handle`, `Set up`).
- Steps are concrete, observable, and ordered.
- Steps encode **target + behavior + edge condition** when relevant.

Step writing pattern:
- `Target — required behavior`
- Example: `Route /auth/login — show generic "Invalid email or password" on credential failure (no enumeration)`

Include explicit edge behavior where relevant:
- invalid/expired tokens
- duplicate conflicts
- auth/permission failures
- degraded dependency behavior

## Output contracts

### Phased format (default for multi-phase plans)

**`plans/prd.yaml`**

```yaml
shared: "./plans/prd/shared.yaml"

toc:
  - "[ ] Phase 1 — <title> (plans/prd/phase-01.yaml)"
```

**`plans/prd/phase-xx.yaml`**

```yaml
# See ./shared.yaml for global constraints and decisions.
phase: 1
title: "<phase title>"
tasks:

- track: intent
  description: Implement <outcome>
  status: pending
  steps:
    - Concrete, testable step
```

**`plans/prd/shared.yaml`**

```yaml
global_constraints: []
decisions: []
assumptions: []
open_questions: []
```

**`plans/progress.md`**

```md
# Progress

- YYYY-MM-DD — <milestone or update>
  - **Status**: done
  - Notes: <what changed>
```

**`plans/research.md`**

```md
# Research Index

- PRD: `plans/prd.yaml`
- Shared decisions: `plans/prd/shared.yaml`
- Phase plans: `plans/prd/`
```

### Flat format (for simple single-phase plans)

**`plans/prd.yaml`**

```yaml
base_url: "http://localhost:3000"  # optional, for projects with UI
dev_command: "npm run dev"          # optional

tasks:
  - track: intent
    description: Clear description of what this task accomplishes
    status: pending
    steps:
      - Step 1 description
      - Step 2 description
```

### Shared conventions

Task key order: `track`, `description`, `status`, optional `headed`, `steps`

`headed: true` marks tasks that require browser-visible verification (e.g. UI flows). Execution agents use this flag to launch a headed browser for visual validation.

Allowed tracks: `intent | experience | data | rules | resilience`

Status semantics:
- phase task status: `pending | in_progress | blocked | done`
- PRD TOC checkbox: `[ ] | [x]`
- progress entry status (`plans/progress.md`): `done | blocked`

`headed` is optional and mostly for `experience` tasks needing browser-visible verification.

## Example

```yaml
# See ./shared.yaml for global constraints and decisions.
phase: 11
title: "Organization member management improvements"
tasks:

- track: experience
  description: Build member table search and role actions
  status: pending
  headed: true
  steps:
    - Route /[orgSlug]/settings/members — add client-side search input filtering by name or email
    - Member rows — show role badge and "You" badge for current user
    - Role dropdown — visible for admin+ only, hidden for members
    - On role update success — show toast "Member role updated" and persist updated badge state
    - On role update failure — show inline/table-level error and keep previous role visible

- track: rules
  description: Implement role-change authorization boundaries
  status: pending
  steps:
    - Admin can change roles only between member and admin
    - Owner required for promotions to owner
    - Sole owner cannot demote self
    - Unauthorized attempts return FORBIDDEN with consistent message "Insufficient permissions."
    - Add test coverage for admin->owner rejection and sole-owner self-demotion rejection
```

## Anti-patterns to avoid

- Vague tasks like "Improve members UX" or "Set up backend".
- Steps without location/context (route/file/service).
- Combining unrelated outcomes in one task.
- Missing failure-path behavior on sensitive flows.
- Rewriting full plan history for a small feature change.
- Over-splitting into too many phases for a small MVP.

## Execution checklist

1. Read existing planning files (if any).
2. Interview with `AskUserQuestion` (or inline fallback).
3. Confirm scope and plan size.
4. Draft tasks using the AI-executable quality bar.
5. Write/update only required files.
6. Summarize assumptions and unresolved questions.

For additional templates and phrase patterns, read `references/plan-format.md`.
