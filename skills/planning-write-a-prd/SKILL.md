---
name: planning-write-a-prd
description: Create a Linear-native PRD by interviewing the user, exploring the codebase, and creating the right Linear container (default: a Project for multi-issue work).
---

# Write a PRD

Create a PRD that is idiomatic to Linear: use Linear fields and relationships for structure, and keep markdown for human context.

## Default Linear model

Prefer this model unless the work is truly small:

- **Project** = delivery container for the PRD
- **Document** = longform spec, if needed
- **Issues** = implementation slices
- **Optional umbrella issue** = lightweight parent issue when sub-issue hierarchy helps execution

Use a **single parent issue instead of a project** only when the feature is small and unlikely to become more than a few implementation issues.

## Process

### 1. Clarify the problem and choose the container

Ask the user for:

- the problem to solve
- desired outcome
- constraints or deadlines
- rough scope
- known solution ideas

Then decide which Linear artifact to create:

- **Project**: default for multi-issue PRDs
- **Parent issue**: only for small, tightly-scoped efforts
- **Document**: add when the PRD needs longform detail; do not cram a giant spec into an issue description

### 2. Explore the repo

Explore the codebase to verify assumptions, understand the current system, and find existing patterns to follow.

### 3. Interview to convergence

Interview the user until you reach shared understanding. Resolve:

- core use cases
- non-goals
- constraints
- rollout and validation expectations
- open questions that materially change scope or architecture

### 4. Sketch modules and testing strategy

Identify the major modules you expect to build or modify. Prefer deep, stable, testable modules over shallow glue.

Check with the user that:

- the module boundaries make sense
- the testing plan matches expectations
- any risky unknowns are called out explicitly

### 5. Draft the PRD

Use the template below. Keep it scannable. The PRD body should support decomposition into issues; it should not be a dumping ground for every implementation detail.

If you have a large inventory of user stories or edge cases, put the exhaustive version in a **Linear document** and summarize only the important ones in the project or issue.

<prd-template>

## Why

The problem from the user's perspective and why it matters now.

## Desired outcome

What success looks like from the user's perspective.

## In scope

The behaviors, workflows, and surfaces included in this effort.

## Out of scope

What this PRD explicitly does not cover.

## Key use cases

A concise numbered list of the most important user stories / use cases needed to break the work into implementation slices.

## Decisions already made

Architectural, product, or UX decisions that are already settled.

## Open questions

Only the questions that materially affect scope, sequencing, or architecture.

## Risks / dependencies

Important constraints, migrations, third-party dependencies, cross-team dependencies, or rollout risks.

## Validation / success signals

How we will know the work is correct or successful. Include testing expectations at the level of behavior, not implementation details.

## Implementation / testing notes

High-signal notes about modules, contracts, schema changes, or prior art for tests. Do NOT include file paths or code snippets.

</prd-template>

### 6. Create the Linear artifacts

Create the chosen Linear artifacts in a Linear-native way:

- **Project**: default PRD container for RAL when the work spans multiple implementation issues
- **Document**: store longform PRD detail here when needed
- **Umbrella issue**: optional lightweight parent issue inside the project if sub-issues will make execution easier

Rules:

- keep project and issue descriptions concise and scannable
- use native Linear relationships instead of markdown sections for structure
- do **not** encode parent-child structure or blockers in markdown
- link the project, document, and umbrella issue to each other where useful

### 7. Hand off cleanly

After creation, share:

- the project URL
- the document URL, if created
- the umbrella issue URL, if created
- a one-paragraph summary of the recommended next step (`/planning-prd-to-issues` or direct execution)
