---
name: planning-prd
description: Create or update PRD plans for features/projects. Use when users ask to plan work, write/refine a PRD, run a planning interview, or update files in plans/. Conduct a deep structured interview, then output AI-executable tasks across intent/experience/data/rules/resilience tracks.
---

# PRD Planning

Plan features and projects with AI-executable tasks. Works for greenfield projects, existing codebases, and simple flat PRDs.

## Execution checklist

1. **Read context** — scan existing planning files, codebase (routes, schema, config, dependencies), and any user-provided prompt before asking anything. Form hypotheses about architecture, constraints, and unknowns.
2. **Interview** with `AskUserQuestion` — conduct deep, multi-round interviews across product and engineering layers. Do not generate the plan until you can write unambiguous steps for every relevant track.
3. **Research synthesis** — compile interview findings into research documents organized by domain (see output contracts).
4. **Confirm** scope, plan size, and phase sequencing with the user.
5. **Draft tasks** using the AI-executable quality bar.
6. **Write/update** all required files (research docs, shared.yaml, phase files, prd.yaml, progress.md).
7. **Summarize** assumptions, decisions, and unresolved questions in `shared.yaml`.

## Interview workflow (required)

Use `AskUserQuestion` for every round. If unavailable, ask equivalent numbered questions inline.

### Rules

1. **Ask 2-4 focused questions per round** across two layers:
   - **Product layer** (what): intent, experience, data
   - **Engineering layer** (how): rules, resilience
2. **Continue round after round** until every relevant track has enough detail to write unambiguous, AI-executable tasks. Do not rush to generate. Expect 5-10+ rounds for full project plans.
3. Probe edge behavior inside relevant track questions — do not postpone all edge cases to a final round.
4. After each round, report **covered vs uncovered tracks** and what gaps remain.
5. Include a **"Generate plan now"** option from **round 3 onward only**, with uncovered tracks listed in the description so the user knows what they're skipping.
6. Stop interviewing immediately if user chooses generate now.
7. **Build on prior answers** — reference specific decisions from earlier rounds to dig deeper. "You said X — does that mean Y in this scenario?"
8. **Offer concrete options** — when a decision has 2-3 obvious approaches, present them with tradeoffs rather than open-ended questions. Force a choice.

### Interview depth by layer

#### Product layer — dig until you have flows, not ideas

- **Intent**: Don't stop at "what does it do." Push to: who benefits most, what gets cut if time runs out, what success looks like in numbers, what explicitly won't be built.
- **Experience**: Walk through every screen transition. What does the user see on first load? After the action? On empty state? On error? On slow network? After they leave and come back? What's the notification model?
- **Data**: Map every entity, every relationship, every lifecycle. What creates it, what reads it, what updates it, what deletes it? What's the cascade behavior? What needs an audit trail?

#### Engineering layer — dig until you have constraints, not vibes

- **Rules**: Enumerate every permission boundary. What can each role do? What happens at the boundary (unauthorized attempt)? What validation runs where (client vs server)? What business rules feel "obvious" but nobody wrote down?
- **Resilience**: What happens when each external dependency fails? What's idempotent? What's the retry story? What data can be stale? What must be consistent? What's the monitoring/alerting story?

#### Cross-cutting probes (weave into relevant rounds)

- **Testing**: What's the confidence threshold? Which flows need integration tests vs unit tests? What's the fixture/seed data story?
- **Performance**: What are the expected cardinalities? What needs pagination? What needs caching? What's the latency budget for key flows?
- **Security**: What's the threat model? Where does user input enter? What needs rate limiting? What needs audit logging?
- **Migration**: Is there existing data to migrate? What's the rollback plan if this ships and breaks? Can this be feature-flagged?

### Question quality bar

Every question must extract information you cannot infer from the codebase or prior answers. Ask questions that expose hidden assumptions and force decisions.

| Track | Insightful questions (not the obvious ones) |
|-------|------------------|
| **Intent** | If you could only ship one part of this, which part unlocks the most value? What's the cost of getting this wrong vs shipping it late? Who's the second-most-important user — do their needs conflict with the primary user? What adjacent features are people going to assume exist? |
| **Experience** | What does the user do right *before* they reach this feature — and right *after*? If the action takes 30 seconds instead of 1, what should they see? What does "undo" look like here? What state carries over between sessions? How does this behave when the user has 3 items vs 3,000? |
| **Data** | What's the lifecycle of this entity — from birth to archive/delete? If you query this table in 6 months, what questions will you wish you'd stored data to answer? What's the write:read ratio? Is there a natural partition key? What needs to survive account deletion? |
| **Rules** | What's the most confusing thing a user could legally do that you'd want to prevent anyway? Which constraints apply differently in a self-serve vs enterprise context? What happens in a multi-user race condition on this resource? What clock does "expires in 24 hours" reference — server, user, or UTC? |
| **Resilience** | If you deployed this at 5pm Friday, what's the 3am page you're most worried about? What's the blast radius if the database is 200ms slower than normal? Which operations must be exactly-once vs at-least-once? What's the "sorry, try again" vs "we'll fix it and email you" boundary? |

**Never ask:**
- "What tech stack are you using?" (read the repo)
- "Do you want tests?" / "Should we handle errors?" (always yes)
- "What's the project about?" (user already told you)
- Generic questions that don't force a specific decision
- Questions answerable by reading the codebase or dependencies
- "How should we structure the code?" (that's your job)

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

**`plans/prd/shared.yaml`** — global constraints, tech decisions, and interview-derived overrides as YAML comments. This is the single source of truth for cross-cutting concerns.
```yaml
base_url: "http://localhost:3000"   # optional
dev_command: "npm run dev"           # optional
# Global constraints as comments — applied to ALL tasks
# Interview decisions that override source docs listed here
global_constraints: []
decisions: []
assumptions: []
open_questions: []
```

**`plans/progress.md`** — dated milestone entries with status (`done | blocked`) and notes.

**`plans/research.md`** — index table linking to all research docs, prd.yaml, shared.yaml, phase files, and override notes from interview decisions.

### Research documents (for medium/large plans)

**`plans/research/`** — one markdown file per domain, synthesized from interview answers. Each doc captures the **decisions made**, not just requirements.

Create research docs when the plan has 3+ phases or spans multiple domains. Organize by topic:

| Document | Contents |
|----------|----------|
| `overview.md` | Product overview, design principles, tech stack, workspace layout |
| `<domain>.md` | Per-domain deep dive: flows, entities, rules, edge cases (e.g., `auth.md`, `organizations.md`, `payments.md`) |
| `decisions.md` | Numbered product + technical decision log with rationale |
| `conventions.md` | Formatting, naming, module patterns, error handling conventions |
| `testing.md` | Strategy, fixtures, test cases, coverage expectations |

Research docs serve as reference material for implementation agents and human reviewers. They're the "why" behind the tasks.

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
