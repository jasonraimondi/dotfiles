---
name: create-prd-plan
description: Create or update feature PRD plans for existing projects. Use when the user wants to plan a new feature, add or refine phases/tasks in an existing plans/ structure, or generate a scoped implementation plan before coding. Ask clarifying questions with AskUserQuestion, then produce AI-executable track-based tasks (intent/experience/data/rules/resilience) with concrete steps and consistent status semantics.
---

# Create PRD Plan

Plan **feature work in an existing project** with minimal-diff updates and high-quality tasks that an AI agent can execute directly.

## Interview-first workflow (required)

1. Use `AskUserQuestion` before writing.
2. Ask 2-4 focused questions per round.
3. Always include **"Generate plan now"** as an option.
4. Show uncovered tracks after each round.
5. If user chooses generate now, stop interviewing and write/update plan files.

## Coverage tracks

- `intent` — scope, goals, boundaries, priorities
- `experience` — UX/UI flows, pages, interactions
- `data` — entities, schema/contracts, persistence
- `rules` — validation, permissions, auth, business logic
- `resilience` — failures, retries, degraded behavior, ops concerns

Do not force all tracks for small features. Cover only what materially affects delivery risk.

## Existing-project behavior

Before editing, read the repo’s current planning files.

### If phased PRD files exist

If `plans/prd.yaml` and `plans/prd/phase-xx.yaml` exist:
- Preserve structure and history.
- Patch only relevant phase(s)/task(s).
- Prefer targeted additions over broad rewrites.
- Keep completed tasks and prior wording intact unless user asks to refactor.

### If non-phased planning files exist

- Follow local conventions.
- Keep interview depth and step quality high.
- Migrate formats only if user requests migration.

### If no planning files exist

- Ask whether to:
  1) create a minimal feature plan in phased format, or
  2) use the `create-new-project-prd-plan` workflow.
- Default to a minimal feature plan if user does not care.

## Plan sizing

Choose the smallest useful plan:
- **Small feature:** 1 phase, 2-5 tasks
- **Medium feature:** 2 phases, 3-7 tasks total
- **Large feature/initiative:** 3+ phases as needed

If uncertain, ask one sizing question and default to the leaner option.

## AI-executable task quality bar (required)

Every task must be structured so an implementation agent can pick it up with minimal interpretation.

For each task:
- One clear outcome (no mixed goals in a single task).
- Correct `track` classification.
- `description` starts with a strong verb (`Build`, `Implement`, `Configure`, `Create`, `Define`, `Write`, `Handle`, `Set up`).
- Steps are concrete, observable, and ordered.
- Steps should encode **target + behavior + edge condition** when relevant.

Step writing pattern:
- `Target — required behavior`
- Example: `Route /auth/login — show generic "Invalid email or password" on credential failure (no enumeration)`

Include explicit edge behavior where relevant:
- invalid/expired tokens
- duplicate conflicts
- auth/permission failures
- degraded dependency behavior

## Output contracts (phased format)

### `plans/prd.yaml`

```yaml
shared: "./plans/prd/shared.yaml"

toc:
  - "[ ] Phase 1 — <title> (plans/prd/phase-01.yaml)"
```

### `plans/prd/phase-xx.yaml`

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

Task key order:
- `track`
- `description`
- `status`
- optional `headed`
- `steps`

Allowed tracks:
- `intent | experience | data | rules | resilience`

Status semantics:
- phase task status: `pending | done`
- PRD TOC checkbox: `[ ] | [x]`
- progress entry status (`plans/progress.md`): `done | blocked`

`headed` is optional and mostly for `experience` tasks needing browser-visible verification.

## Strong feature-phase example

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

- track: data
  description: Define invitation cancellation contract and persistence updates
  status: pending
  steps:
    - Service cancel-invitation validates org scope before mutation
    - Soft-delete invitation record instead of hard-delete
    - Dispatch audit.log event member.invitation_cancelled via safe fire-and-forget path
    - Add test ensuring cross-org cancellation attempt is rejected
```

## Anti-patterns to avoid

- Vague tasks like "Improve members UX".
- Steps without location/context.
- Combining unrelated outcomes in one task.
- Missing failure-path behavior on sensitive flows.
- Rewriting full plan history for a small feature.

## Execution checklist

1. Read existing planning files.
2. Interview with `AskUserQuestion`.
3. Confirm scope and size (1 phase, 2 phases, or larger).
4. Draft tasks using the AI-executable quality bar.
5. Update only required files.
6. Summarize assumptions and unresolved questions.

For templates and phrase patterns, read `references/plan-format.md`.
