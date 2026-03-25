---
name: planning-write-a-prd
description: Create a PRD by interviewing the user, exploring the codebase, and writing a structured YAML plan to ./plans/{slug}/prd.yaml. Use when user says "write a PRD", "plan this feature", "create a plan", or wants structured project planning.
---

# Write a PRD

Create a PRD as a structured YAML file in the project's `./plans/` directory.

## Plan structure

Every PRD lives in its own directory:

```
./plans/{project-slug}/
  prd.yaml
  issues/          # created later by /planning-prd-to-issues
```

## Process

### 1. Clarify the problem

Ask the user for:

- the problem to solve
- desired outcome
- constraints or deadlines
- rough scope
- known solution ideas

### 2. Explore the repo

Explore the codebase to verify assumptions, understand the current system, and find existing patterns.

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

Write the PRD as a YAML file using this schema:

```yaml
name: "Project Name"
slug: project-name
status: draft  # draft | active | complete | archived
created: YYYY-MM-DD
updated: YYYY-MM-DD

description: |
  One-line summary.

why: |
  The problem from the user's perspective and why it matters now.

outcome: |
  What success looks like.

in_scope:
  - "Behavior or surface included"

out_of_scope:
  - "What this PRD explicitly does not cover"

use_cases:
  - id: UC-1
    description: "..."
  - id: UC-2
    description: "..."

decisions:
  - "Decision that is already settled"

open_questions:
  - "Question that materially affects scope or architecture"

risks:
  - "Constraint, dependency, or rollout risk"

validation:
  - "How we know the work is correct or successful"

notes: |
  High-signal notes about modules, contracts, schema changes, or testing strategy.

# Optional — used by implementation agent for headed verification
dev_command: "npm run dev"
base_url: "http://localhost:3000"
```

Keep it scannable. The PRD should support decomposition into issues — not be a dumping ground for every implementation detail.

### 6. Write the file

Create `./plans/{slug}/prd.yaml` using the drafted content.

Rules:

- the `slug` is a kebab-case version of the project name, used as the directory name
- use_cases are numbered (UC-1, UC-2, ...) so issues can reference them
- do not include file paths or code snippets in the PRD

### 7. Hand off cleanly

After creation, share:

- the file path to the PRD
- a one-paragraph summary of the recommended next step (`/planning-prd-to-issues`)
