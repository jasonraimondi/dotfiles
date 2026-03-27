---
name: sync-plan-to-linear
description: Sync a local ./plans/{slug}/ directory to Linear — creates or updates projects, documents, issues, and dependencies. Writes Linear IDs back to local YAML for idempotent re-syncs. Use when user says "sync to linear", "push to linear", "publish plan", or wants to mirror local plan state in Linear.
allowed-tools: Bash(linear:*), Bash(jq:*), Bash(cat:*), Bash(mktemp:*)
---

# Sync Plan to Linear

One-way sync: local YAML is source of truth, Linear is the sync target. Safe to run repeatedly — artifacts with existing Linear IDs are updated, new ones are created.

## Input

- **Plan**: project slug or path (e.g., `auth` or `./plans/auth/`)
- **Team** (optional): Linear team key (e.g., `RAL`)

If plan is not provided, ask: "Which plan should I sync? (project slug or path)"

## Linear ID storage

After creating Linear artifacts, write IDs back under a `linear` key in each YAML file.

**prd.yaml** additions:

```yaml
linear:
  team_key: RAL
  project_id: "project-uuid"
  project_url: "https://linear.app/..."
  document_id: "doc-slug-or-uuid"
  document_url: "https://linear.app/..."
```

**Issue YAML** additions:

```yaml
linear_id: RAL-123
linear_url: "https://linear.app/..."
```

## Process

### 1. Read local state

Read `./plans/{slug}/prd.yaml` and all `./plans/{slug}/issues/*.yaml`. Validate that `prd.yaml` exists.

### 2. Resolve Linear team

Resolve the team in priority order:

1. User-provided team argument (highest priority)
2. `linear.team_key` in `prd.yaml`
3. `team_id` from `.linear.toml` (checked at repo root and standard config paths)
4. `linear team list` — use directly if one team, ask the user if multiple

Write the resolved `team_key` back to `prd.yaml` if it changed or was missing.

### 3. Ensure labels exist

Run `linear label list --team {team_key} --json` and check for **AFK** and **HITL** labels. Create any that are missing:

```bash
linear label create --name AFK --team {team_key} --color "#0EA5E9"
linear label create --name HITL --team {team_key} --color "#F59E0B"
```

### 4. Sync project

**Create** (no `linear.project_id`):

```bash
linear project create \
  --name "{prd.name}" \
  --description "{prd.description}" \
  --team {team_key} \
  --status started
```

Capture the project ID and URL from the output. Write `linear.project_id` and `linear.project_url` back to `prd.yaml`.

**Update** (has `linear.project_id`): The CLI has no `project update` command. Use `linear api` with a GraphQL mutation if the project name or description has changed. Skip if unchanged.

### 5. Sync document

Convert PRD YAML fields to markdown and write to a temp file. See [formatting rules](#prd-document-format) below.

**Create** (no `linear.document_id`):

```bash
linear document create \
  --title "{prd.name} — PRD" \
  --content-file /tmp/prd-content.md \
  --project {project_slug_or_id}
```

Write `linear.document_id` and `linear.document_url` back to `prd.yaml`.

**Update** (has `linear.document_id`):

```bash
linear document update {document_id} --content-file /tmp/prd-content.md
```

### 6. Sync issues

For each issue YAML, ordered by `id`:

**Map fields:**

| Local field | Linear flag |
|---|---|
| `name` | `--title` |
| `priority` | `--priority` (urgent=1, high=2, medium=3, low=4) |
| `points` | `--estimate` |
| `status` | `--state` (use the status name directly — Linear matches case-insensitively) |
| `labels[]` | `--label` (repeat for each) |
| `assignee` | `--assignee` (if not null) |

Convert issue YAML fields to a markdown description and write to a temp file. See [formatting rules](#issue-description-format) below.

**Create** (no `linear_id`):

```bash
linear issue create \
  --title "{name}" \
  --description-file /tmp/issue-desc.md \
  --team {team_key} \
  --project "{prd.name}" \
  --priority {mapped_priority} \
  --estimate {points} \
  --state "{status}" \
  --label AFK \
  --no-interactive
```

Capture the issue identifier (e.g., `RAL-123`) from output. Write `linear_id` and `linear_url` back to the issue YAML.

**Update** (has `linear_id`):

```bash
linear issue update {issue_id} \
  --title "{name}" \
  --description-file /tmp/issue-desc.md \
  --priority {mapped_priority} \
  --estimate {points} \
  --state "{status}" \
  --label AFK
```

### 7. Wire dependencies

After all issues have Linear IDs, sync `blocked_by` relationships:

```bash
linear issue relation add {issue_id} blocked-by {blocking_issue_id}
```

For each issue, compare its `blocked_by` list against existing relations (via `linear issue relation list {issue_id}`). Add missing relations, skip existing ones.

### 8. Write all YAML changes

Write all updated YAML files with the new `linear` fields. Update `prd.yaml` `updated` date.

### 9. Report

```text
Plan: {project name}
Team: {team_key}
Project: {project_url}
Document: {document_url or "none"}
Issues synced: {created_count} created, {updated_count} updated
Dependencies: {relation_count} wired
```

---

## Formatting rules

### PRD document format

Convert `prd.yaml` fields to this markdown for the Linear document:

```markdown
## Why

{why}

## Desired outcome

{outcome}

## In scope

- {item per in_scope entry}

## Out of scope

- {item per out_of_scope entry}

## Key use cases

1. **UC-1**: {description}
2. **UC-2**: {description}

## Decisions

- {item per decisions entry}

## Open questions

- {item per open_questions entry}

## Risks

- {item per risks entry}

## Validation

- {item per validation entry}

## Notes

{notes}
```

### Issue description format

Convert issue YAML fields to this markdown for the Linear issue description:

```markdown
## Outcome

{outcome}

## Scope

{scope}

## Acceptance criteria

- [ ] {item per acceptance_criteria entry}

## Use cases

{comma-separated use_case references}

## Notes

{notes}
```

Omit any section where the local field is empty or null.
