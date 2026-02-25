---
name: create-new-project-prd-plan
description: Create a new project PRD plan from scratch. Use when the user is starting a greenfield project, wants to bootstrap plans/ planning files, or asks for a roadmap split into plans/prd.yaml plus plans/prd/phase-xx.yaml. Interview with AskUserQuestion, then generate AI-executable phased tasks across intent/experience/data/rules/resilience with concrete steps and consistent status semantics.
---

# Create New Project PRD Plan

Create a **greenfield project plan** with a clean phased structure under `plans/`, written so implementation agents can execute tasks directly.

## Interview-first workflow (required)

1. Use `AskUserQuestion` before writing.
2. Ask 2-4 focused questions per round.
3. Always include **"Generate plan now"** as an option.
4. Show uncovered tracks after each round.
5. If user chooses generate now, stop interviewing and write plan files.

## Coverage tracks

- `intent` — product goals, scope boundaries, success criteria
- `experience` — key user flows, screens, UX states and messaging
- `data` — entities, storage model, contracts, migration/seed needs
- `rules` — validation, auth, permissions, business constraints
- `resilience` — failures, retries, health checks, observability, ops readiness

For small MVPs, cover only materially relevant tracks; do not force all five.

## New-project file set

Create/maintain:
- `plans/prd.yaml`
- `plans/prd/shared.yaml`
- `plans/prd/phase-xx.yaml`
- `plans/research.md` (index-level pointer)
- `plans/progress.md`

## Plan sizing

Choose the smallest plan that captures dependencies and risk:
- **Small MVP:** 1-2 phases
- **Medium product:** 3-6 phases
- **Large initiative:** 7+ phases

Do not force long roadmaps for simple projects.

## Phase sequencing guidance

Use coherent delivery slices and adjust to user priorities:
1. Foundation/scaffolding/tooling
2. Core data/domain/rules
3. User-facing experience and flows
4. Hardening/resilience/operations

## AI-executable task quality bar (required)

Every task must be implementation-ready.

For each task:
- One explicit outcome.
- Correct `track` classification.
- Verb-led `description` (`Build`, `Implement`, `Configure`, `Create`, `Define`, `Write`, `Handle`, `Set up`).
- Ordered, concrete, testable steps.
- Steps encode **target + behavior + edge condition** when relevant.

Step writing pattern:
- `Target — required behavior`
- Example: `Route /auth/register — on duplicate email, show inline error without revealing account metadata`

Include explicit edge behavior where risk exists:
- invalid/expired tokens
- duplicate conflicts
- authorization failures
- degraded dependency behavior

## Output contracts

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

`headed` is optional and mostly for `experience` tasks requiring browser-visible verification.

## Strong greenfield phase example

```yaml
# See ./shared.yaml for global constraints and decisions.
phase: 1
title: "Foundation and auth baseline"
tasks:

- track: intent
  description: Scaffold monorepo and baseline delivery commands
  status: pending
  steps:
    - Create workspace manifest and root scripts for dev, build, lint, test, check
    - Configure strict TypeScript baseline and verify workspace install resolves cleanly
    - Add CI-friendly command parity so local and CI checks run the same task names

- track: data
  description: Define initial auth and organization persistence model
  status: pending
  steps:
    - Create core tables for user, session, organization, member, invitation
    - Add soft-delete columns where recoverability is required
    - Add uniqueness constraints for active org slug and active org membership pairs
    - Add migration and verify clean apply on fresh database

- track: rules
  description: Implement auth and org access guardrails
  status: pending
  steps:
    - Require authenticated session for app routes except public allowlist
    - Resolve org context by slug and return 404 for missing org or non-member
    - Enforce role hierarchy for owner/admin/member actions
    - Add tests for unauthorized access and non-member org access behavior
```

## Anti-patterns to avoid

- Vague tasks like "Set up backend".
- Steps without file/route/service context.
- Multiple unrelated outcomes in one task.
- Missing failure-path behavior on critical auth/data flows.
- Over-splitting into too many phases for a small MVP.

## Execution checklist

1. Interview with `AskUserQuestion`.
2. Confirm scope and plan size.
3. Initialize `plans/` files.
4. Draft tasks using the AI-executable quality bar.
5. Write phased tasks with clear dependency order.
6. Summarize assumptions and open questions.

For templates and phrase patterns, read `references/plan-format.md`.
