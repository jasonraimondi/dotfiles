# Existing-Project Feature Plan Format

Use this reference when planning new features in repos that already have code (and often existing plan files).

## Preferred workflow

1. Read existing planning artifacts.
2. Keep structure stable.
3. Add focused updates with minimal diff.

## Planning modes

### A) Existing phased system
Detected by files like:
- `plans/prd.yaml`
- `plans/prd/shared.yaml`
- `plans/prd/phase-xx.yaml`

Action:
- Update relevant phase file(s) and TOC only.
- Avoid rewriting completed sections.

### B) Existing non-phased system
Action:
- Keep project-native format.
- Preserve existing conventions.

### C) No planning files
Action:
- Ask user to choose:
  - minimal phased feature plan, or
  - new-project planning flow.

## Plan sizing

- **Small feature**: 1 phase, 2-5 tasks
- **Medium feature**: 2 phases, 3-7 tasks total
- **Large feature**: 3+ phases

Default lean when unsure.

## Allowed tracks

- `intent`
- `experience`
- `data`
- `rules`
- `resilience`

## Status semantics

- `plans/prd/phase-xx.yaml` task status: `pending | done`
- `plans/prd.yaml` TOC checkboxes: `[ ] | [x]`
- `plans/progress.md` entry `**Status**`: `done | blocked`

## AI-executable task checklist

For each task, verify:
- Outcome is singular and explicit.
- Description starts with a strong verb.
- Steps are ordered and testable.
- Steps include where change happens (route/file/service/procedure).
- Failure/edge behavior is explicit where risk exists.
- Permission and validation constraints are spelled out when relevant.

## Task shape

```yaml
- track: experience
  description: Build members table filtering and role controls
  status: pending
  headed: true
  steps:
    - Route /[orgSlug]/settings/members — add client-side search by name/email
    - Role dropdown — show for admin+ only, hidden for members
    - On role update error — keep previous role visible and show inline error
```

## Strong cross-track mini example

```yaml
tasks:

- track: intent
  description: Implement scoped member-management upgrade without changing invitation flow URLs
  status: pending
  steps:
    - Keep existing routes stable (/[orgSlug]/settings/members, /auth/invite/accept)
    - Limit scope to search/filter, role actions, and invitation cancellation
    - Defer pagination and bulk actions out of this feature

- track: rules
  description: Implement role hierarchy checks for member role changes
  status: pending
  steps:
    - Admin can toggle member↔admin only
    - Owner required to assign owner role
    - Sole owner cannot demote self
    - Return FORBIDDEN on unauthorized role updates

- track: resilience
  description: Handle member update failures with non-destructive UI state
  status: pending
  steps:
    - If update call fails, keep prior table state unchanged
    - Show error toast and inline row-level error
    - Allow immediate retry without page reload
```

## Description patterns

Preferred:
- `Build <user-facing capability>`
- `Implement <system behavior>`
- `Configure <tooling/infrastructure>`
- `Define <schema/contracts>`
- `Write <tests/automation>`

Avoid vague descriptions.

## Step patterns

- Path-first: `apps/web/src/routes/...`
- Route-first: `Route /settings/security ...`
- Behavior-first: `On success — redirect to /orgs`
- Constraint-first: `404 for missing org or non-member`

Include critical edge behavior inline:
- expired/invalid tokens
- duplicate conflicts
- role/permission boundaries
- degraded dependency behavior
