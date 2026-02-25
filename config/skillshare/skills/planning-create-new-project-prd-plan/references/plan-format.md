# New-Project PRD Plan Format

Use this reference when creating planning files for a greenfield project.

## Canonical files

- `plans/prd.yaml`
- `plans/prd/shared.yaml`
- `plans/prd/phase-01.yaml` ... `plans/prd/phase-xx.yaml`
- `plans/research.md`
- `plans/progress.md`

## Preferred workflow

1. Interview for scope and constraints.
2. Size plan to project complexity.
3. Sequence phases by dependencies.
4. Write AI-executable tasks and steps.

## Plan sizing

- **Small MVP**: 1-2 phases
- **Medium product**: 3-6 phases
- **Large initiative**: 7+ phases

Default lean when unsure.

## Suggested phase layout

1. Setup/foundation
2. Data/domain/rules
3. Product experience flows
4. Resilience/ops/CI

Adapt order to project-specific priorities.

## Allowed tracks

- `intent`
- `experience`
- `data`
- `rules`
- `resilience`

## Status semantics

- `plans/prd/phase-xx.yaml` task status: `pending | done`
- `plans/prd.yaml` TOC checkbox: `[ ] | [x]`
- `plans/progress.md` `**Status**`: `done | blocked`

## AI-executable task checklist

For each task, verify:
- Single explicit outcome.
- Description starts with a strong verb.
- Steps are ordered and testable.
- Steps point to concrete targets (route/file/module/service).
- Failure and edge behavior are explicit where relevant.
- Dependency order is clear across tasks/phases.

## Phase task template

```yaml
# See ./shared.yaml for global constraints and decisions.
phase: 1
title: "Monorepo setup"
tasks:

- track: intent
  description: Scaffold workspace structure and base scripts
  status: pending
  steps:
    - Create workspace manifest and root scripts
    - Verify install and basic dev command run
```

## Strong mini example

```yaml
tasks:

- track: experience
  description: Build authentication entry flows
  status: pending
  headed: true
  steps:
    - Route /auth/register — collect name, email, password, confirm password
    - Route /auth/login — support credential sign-in and provider sign-in options
    - Invalid credentials — show generic inline error without email enumeration

- track: resilience
  description: Implement startup and health checks
  status: pending
  steps:
    - On app startup, verify database connectivity and fail fast with clear error if unreachable
    - Expose GET /health returning dependency health summary
    - Log degraded mode when non-critical dependencies are unavailable
```

## Style

- Description starts with a strong verb.
- Steps are concrete and implementation-oriented.
- Include expected success/failure behavior where relevant.
- Avoid vague tasks and abstract bullets.
