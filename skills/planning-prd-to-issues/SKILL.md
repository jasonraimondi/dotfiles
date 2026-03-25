---
name: planning-prd-to-issues
description: Break a PRD project or umbrella issue into independently grabbable Linear issues using thin vertical slices and native Linear relationships.
---

# PRD to Issues

Break a PRD into implementation issues that are idiomatic to Linear.

## Default Linear model

Prefer this model:

- **Project** = PRD container
- **Issues** = implementation slices
- **Native dependencies** = sequencing
- **Labels** = AFK / HITL routing
- **Optional umbrella issue** = sub-issue parent when hierarchy helps

Use markdown for context only. Do not store workflow structure in markdown.

## Process

### 1. Locate the PRD container

Ask the user for the Linear **project** identifier or URL. If the user only has an umbrella issue, accept that too.

If the PRD is not already in your context window, fetch the project or issue from Linear. Also fetch any linked document or description that contains the PRD.

### 2. Explore the codebase (if needed)

If you have not already explored the codebase, do so to understand the current system and likely slice boundaries.

### 3. Draft vertical slices

Break the PRD into **tracer-bullet** issues. Each issue should be a thin vertical slice that cuts through all relevant layers end-to-end, not a horizontal slice of one layer.

Slices may be labeled **AFK** or **HITL**:

- **AFK**: can be implemented and merged without human intervention
- **HITL**: requires human input such as a product decision, UX review, or architectural choice

Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but complete path through all relevant layers
- A completed slice is demoable or independently verifiable on its own
- Prefer many thin slices over few thick ones
- Avoid layer-only tickets unless they unlock multiple later slices or materially reduce risk
</vertical-slice-rules>

### 4. Review the breakdown with the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Routing label**: AFK / HITL
- **Initial state**: usually **Backlog**, or **Todo** if it is ready to be picked up immediately; reserve **Blocked** for work that has started and is awaiting an external unblock
- **Blocked by**: which other slices must complete first
- **Use cases covered**: which PRD use cases or user stories this addresses
- **Acceptance outline**: 2-4 bullets

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependencies correct?
- Should any slices be merged or split further?
- Are the right slices marked AFK vs HITL?
- Which slices should start in Todo versus stay in Backlog?
- Are any slices already known to require a post-start **Blocked** state because they depend on an external unblock or decision?

Iterate until the user approves the breakdown.

### 5. Create the Linear issues

Create the approved slices in a Linear-native way.

For each slice:

- attach it to the same **project** as the PRD, if a project exists
- if there is an umbrella issue and hierarchy helps, create it as a **sub-issue** of that umbrella issue
- set the initial state to **Backlog** by default; use **Todo** only for slices that are ready to be picked up now
- reserve **Blocked** for slices that have started and are actively waiting on an external dependency, decision, or unblock
- apply the **AFK** or **HITL** label
- set native **blocked-by dependencies** in Linear
- keep the description concise using the template below

You may create issues in dependency order or create them first and then wire up dependencies. In either case, keep the dependency graph in Linear itself, not in markdown.

<issue-template>
## Outcome

A concise description of the user-visible or system-visible increment this slice delivers.

## Scope

What is included in this slice. Keep it narrow.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Notes / links

- PRD project or umbrella: <identifier or URL>
- Relevant use cases: <numbers or short references>
- Important constraints or decisions
  </issue-template>

Rules:

- Do **not** add `Parent PRD` or `Blocked by` markdown sections
- Put parent-child relationships in native Linear hierarchy
- Put sequencing in native Linear dependencies
- Use labels rather than prose to mark AFK / HITL

### 6. Confirm the result

After creation, share:

- the project URL or umbrella issue URL
- the created issue identifiers in dependency order
- which issues are ready now in **Todo**
- which issues remain parked in **Backlog**
