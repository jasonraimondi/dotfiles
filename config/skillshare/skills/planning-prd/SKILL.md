---
name: planning-prd
description: Create or update PRD plans for features/projects. Use when users ask to plan work, write/refine a PRD, run a planning interview, or update files in plans/. Conduct a deep structured interview, then output AI-executable tasks across intent/experience/data/rules/resilience tracks.
---

# PRD Planning

Plan features and projects with AI-executable tasks. Works for greenfield projects, existing codebases, and simple flat PRDs.

## Execution checklist

1. **Read context** — scan existing planning files and relevant codebase (routes, schema, config) before asking anything.
2. **Interview** with `AskUserQuestion` — continue across multiple rounds until all relevant tracks have concrete, decision-level detail. Do not generate the plan until you can write unambiguous steps.
3. **Confirm** scope and plan size with the user.
4. **Draft tasks** using the AI-executable quality bar.
5. **Write/update** only required files.
6. **Summarize** assumptions and unresolved questions in `shared.yaml` or inline.

## Interview workflow (required)

Use `AskUserQuestion` for every round. If unavailable, ask equivalent numbered questions inline.

### Rules

1. **Ask 2-4 focused questions per round** across two layers:
   - **Product layer** (what): intent, experience, data
   - **Engineering layer** (how): rules, resilience
2. **Continue round after round** until every relevant track has enough detail to write unambiguous, AI-executable tasks. Do not rush to generate.
3. Probe edge behavior inside relevant track questions — do not postpone all edge cases to a final round.
4. After each round, report **covered vs uncovered tracks** and what gaps remain.
5. Include a **"Generate plan now"** option from **round 3 onward only**, with uncovered tracks listed in the description so the user knows what they're skipping.
6. Stop interviewing immediately if user chooses generate now.

### Question quality bar

Every question must extract information you cannot infer from the codebase or prior answers. Ask questions that expose hidden assumptions and force decisions.

| Track | Example questions |
|-------|------------------|
| **Intent** | What does success look like in 2 weeks vs 2 months? What's explicitly out of scope? Which user segment matters most for v1? What existing behavior must not break? |
| **Experience** | Walk me through the exact flow — what does the user see at each step? What happens when the list is empty / the request is slow / the action fails? Where does the user land after completing the action? Are there intermediate states (loading, partial, optimistic)? |
| **Data** | What's the source of truth? What happens to this data when [related entity] is deleted? Are there uniqueness constraints? What needs to be queryable vs just stored? What's the expected cardinality? |
| **Rules** | Who can do this and who can't? What happens when someone unauthorized tries? Are there rate limits, size limits, or time-window constraints? What business rules feel "obvious" but aren't written down? |
| **Resilience** | What happens if [dependency] is down? Is this idempotent? What if the user double-submits? What's the rollback story? Does this need to degrade gracefully? |

**Never ask:**
- "What tech stack are you using?" (read the repo)
- "Do you want tests?" / "Should we handle errors?" (always yes)
- "What's the project about?" (user already told you)
- Generic questions that don't force a specific decision

## Coverage tracks

- `intent` — scope, goals, boundaries, success criteria, priorities
- `experience` — UX/UI flows, pages, interactions, empty/loading/error states
- `data` — entities, schema/contracts, persistence, relationships
- `rules` — validation, permissions, auth, business logic, constraints
- `resilience` — failures, retries, degraded behavior, health checks, ops concerns

Skip tracks only when genuinely irrelevant (e.g., `resilience` for a static content change). When in doubt, ask — do not silently skip.

## Context detection

Before writing, read the repo's current planning files.

| Scenario | Action |
|----------|--------|
| **Existing phased PRD** (`plans/prd.yaml` + `plans/prd/phase-xx.yaml`) | Preserve structure/history. Patch only relevant phases/tasks. Keep completed tasks intact unless user asks to refactor. |
| **Existing non-phased plans** | Follow local conventions. Keep interview depth and step quality high. Migrate only if user requests. |
| **No planning files** (existing project) | Ask: minimal feature plan or full project plan? Default to minimal. |
| **Greenfield** | Create full structure: `plans/prd.yaml`, `plans/prd/shared.yaml`, `plans/prd/phase-xx.yaml`, `plans/progress.md`, `plans/research.md`. |

## Plan sizing

Choose the smallest useful plan:

| Context | Small | Medium | Large |
|---------|-------|--------|-------|
| Feature | 1 phase, 2-5 tasks | 2 phases, 3-7 tasks | 3+ phases |
| Project | 1-2 phases | 3-6 phases | 7+ phases |

If uncertain, ask one sizing question and default to the leaner option.

## Phase sequencing (greenfield)

1. Foundation / scaffolding / tooling
2. Core data / domain / rules
3. User-facing experience and flows
4. Hardening / resilience / operations

Adapt to project-specific priorities.

## AI-executable task quality bar (required)

Every task must be structured so an implementation agent can pick it up with minimal interpretation.

- **One clear outcome** per task (no mixed goals).
- Correct `track` classification.
- `description` starts with a strong verb: `Build`, `Implement`, `Configure`, `Create`, `Define`, `Write`, `Handle`, `Set up`.
- Steps are concrete, observable, and ordered.
- Steps encode **target + behavior + edge condition** when relevant.

Step pattern: `Target — required behavior`
Example: `Route /auth/login — show generic "Invalid email or password" on credential failure (no enumeration)`

Include explicit edge behavior: invalid/expired tokens, duplicate conflicts, auth failures, degraded dependencies.

## Output contracts

### Phased format (default for multi-phase)

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

**`plans/progress.md`** — dated milestone entries with status (`done | blocked`) and notes.

**`plans/research.md`** — index linking to `prd.yaml`, `shared.yaml`, and phase files.

### Flat format (simple single-phase plans)

```yaml
base_url: "http://localhost:3000"  # optional
dev_command: "npm run dev"          # optional
tasks:
  - track: intent
    description: Clear description of what this task accomplishes
    status: pending
    steps:
      - Step 1 description
```

### Conventions

- Task key order: `track`, `description`, `status`, optional `headed`, `steps`
- `headed: true` — task requires browser-visible verification (execution agents launch a headed browser). Mostly for `experience` tasks.
- Allowed tracks: `intent | experience | data | rules | resilience`
- Task status: `pending | in_progress | blocked | done`
- TOC checkbox: `[ ] | [x]`

## Example

```yaml
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

## Anti-patterns

- Vague tasks like "Improve members UX" or "Set up backend"
- Steps without location/context (route/file/service)
- Combining unrelated outcomes in one task
- Missing failure-path behavior on sensitive flows
- Rewriting full plan history for a small feature change
- Over-splitting into too many phases for a small MVP

For additional step-writing patterns, read `references/plan-format.md`.
