---
name: planning-prd
description: Create or update PRD plans. Use when users ask to plan work, write a PRD, run a planning interview, or update plans/. Deep structured interview, then AI-executable tasks.
---

# PRD Planning

Plan features and projects with AI-executable tasks. Works for greenfield projects, existing codebases, and simple flat PRDs.

## Execution checklist

1. **Read context** — scan existing planning files, codebase (routes, schema, config, deps), and any user-provided prompt before asking anything. Form hypotheses about architecture, constraints, and unknowns.
2. **Interview** with `AskUserQuestion` — conduct deep, multi-round interviews across product and engineering layers. Do not generate the plan until you can write unambiguous steps for every relevant track.
3. **Research synthesis** — compile interview findings into research documents organized by domain (see output contracts).
4. **Confirm** scope, plan size, and phase sequencing with the user.
5. **Draft tasks** using the AI-executable quality bar.
6. **Write/update** all required files (research docs, shared.yaml, phase files, prd.yaml, progress.md).
7. **Summarize** assumptions, decisions, and unresolved questions in `shared.yaml`.

## Interview workflow (required)

Use `AskUserQuestion` for every round. If unavailable, ask equivalent numbered questions inline.

### Rules

1. **2-4 focused questions per round** across two layers:
   - **Product** (what): intent, experience, data
   - **Engineering** (how): rules, resilience
2. **Continue until every relevant track has enough detail** to write unambiguous, AI-executable tasks. Expect 5-10+ rounds for full project plans. Do not rush.
3. **Probe edge behavior inline** — do not postpone edge cases to a final round.
4. After each round, report **covered vs uncovered tracks** and remaining gaps.
5. Offer **"Generate plan now"** from **round 3 onward only**, listing uncovered tracks in the description.
6. Stop interviewing immediately if user chooses to generate now.
7. **Build on prior answers** — reference specific earlier decisions. "You said X — does that mean Y in this scenario?"
8. **Offer concrete options with tradeoffs** rather than open-ended questions. Force choices.
9. **Never ask** what's inferrable from the codebase, questions with obvious answers ("Do you want tests?"), or questions about code structure (that's your job).

### Interview depth

#### Product layer — dig until you have flows, not ideas

- **Intent**: Push beyond "what does it do" to: who benefits most, what gets cut first, what success looks like in numbers, what's explicitly out of scope.
- **Experience**: Walk every screen transition — first load, action complete, empty state, error, slow network, return visit, notification model.
- **Data**: Map every entity, relationship, and lifecycle (CRUD + cascade + audit trail).

#### Engineering layer — dig until you have constraints, not vibes

- **Rules**: Enumerate permission boundaries, validation locations (client vs server), and unwritten business rules.
- **Resilience**: Dependency failure modes, idempotency, retry strategy, staleness tolerance, consistency requirements, monitoring.

#### Cross-cutting probes (weave into relevant rounds)

- **Testing**: Confidence threshold, integration vs unit, fixture/seed data.
- **Performance**: Cardinalities, pagination, caching, latency budgets.
- **Security**: Threat model, input boundaries, rate limiting, audit logging.
- **Migration**: Existing data, rollback plan, feature-flag feasibility.

### Question quality

Every question must extract information you cannot infer from the codebase or prior answers. Prioritize questions that expose hidden assumptions and force decisions:

- **Intent**: What part ships first to unlock the most value? What's the cost of wrong vs late? Do secondary users' needs conflict with primary?
- **Experience**: What happens right before/after this feature? What does "undo" look like? How does it behave at 3 items vs 3,000?
- **Data**: What's the entity lifecycle from birth to deletion? What queries will you wish you'd stored data for in 6 months? What survives account deletion?
- **Rules**: What's the most confusing thing a user could legally do that you'd still want to prevent? What differs between self-serve and enterprise? What about multi-user race conditions?
- **Resilience**: If deployed Friday at 5pm, what's the 3am page? What's the blast radius of 200ms DB slowdown? What's "try again" vs "we'll email you"?

## Context detection

Before writing, read the repo's current planning files.

| Scenario | Action |
|----------|--------|
| **Existing phased PRD** (`plans/prd.yaml` + phase files) | Preserve structure/history. Patch only relevant phases/tasks. Keep completed tasks intact. |
| **Existing non-phased plans** | Follow local conventions. Keep interview depth and step quality high. Migrate only if user requests. |
| **No planning files** (existing project) | Ask: minimal feature plan or full project plan? Default to minimal. |
| **Greenfield** | Create full structure: `plans/prd.yaml`, `plans/prd/shared.yaml`, `plans/prd/phase-xx.yaml`, `plans/progress.md`, `plans/research.md`. |

## Plan sizing

Choose the smallest useful plan:

| Context | Small | Medium | Large |
|---------|-------|--------|-------|
| Feature | 1 phase, 2-5 tasks | 2 phases, 3-7 tasks | 3+ phases |
| Project | 1-2 phases | 3-6 phases | 7+ phases |

Default to the leaner option when uncertain.

## AI-executable task quality bar (required)

Every task must be structured so an implementation agent can pick it up with minimal interpretation.

- **One clear outcome** per task (no mixed goals).
- Correct `track` classification: `intent | experience | data | rules | resilience`. Skip tracks only when genuinely irrelevant — when in doubt, ask.
- `description` starts with a strong verb: `Build`, `Implement`, `Configure`, `Create`, `Define`, `Write`, `Handle`, `Set up`.
- Steps are concrete, observable, and ordered.
- Steps encode **target + behavior + edge condition** when relevant.

Step pattern: `Target — required behavior`
Example: `Route /auth/login — show generic "Invalid email or password" on credential failure (no enumeration)`

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

**`plans/prd/shared.yaml`** — single source of truth for cross-cutting concerns.
```yaml
base_url: "http://localhost:3000"   # optional
dev_command: "npm run dev"          # optional
global_constraints: []
decisions: []
assumptions: []
open_questions: []
```

**`plans/progress.md`** — dated milestone entries with status (`done | blocked`) and notes.

**`plans/research.md`** — index linking to all research docs, prd.yaml, shared.yaml, and phase files.

### Research documents (medium/large plans, 3+ phases)

**`plans/research/`** — one markdown file per domain capturing **decisions made**, not just requirements.

| Document | Contents |
|----------|----------|
| `overview.md` | Product overview, design principles, tech stack, workspace layout |
| `<domain>.md` | Per-domain deep dive: flows, entities, rules, edge cases |
| `decisions.md` | Numbered decision log with rationale |
| `conventions.md` | Naming, module patterns, error handling conventions |
| `testing.md` | Strategy, fixtures, test cases, coverage expectations |

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
- `headed: true` — task requires browser-visible verification. Mostly for `experience` tasks.
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
