---
name: sync-linear-to-plan
description: Pull current state from Linear back into local ./plans/{slug}/ YAML files — updates status, assignee, priority, labels, and points. Also imports new issues created directly in Linear. Use when user says "pull from linear", "sync from linear", "update plan from linear", or wants local files to reflect Linear's current state.
allowed-tools: Bash(linear:*), Bash(jq:*), Bash(cat:*), Bash(mktemp:*)
---

# Sync Linear to Plan

One-way sync: Linear is source of truth for **workflow fields**, local YAML is updated to match. Spec fields (outcome, scope, acceptance criteria) are never overwritten — those are owned locally.

## Input

- **Plan**: project slug or path (e.g., `auth` or `./plans/auth/`)
- **Team** (optional): Linear team key (e.g., `RAL`)

If plan is not provided, ask: "Which plan should I pull? (project slug or path)"

## Field ownership

Fields are split by who owns them:

**Linear owns** (pulled back on sync):

| Linear field | Local YAML field |
|---|---|
| State name | `status` (normalized to lowercase kebab-case) |
| Assignee username | `assignee` |
| Priority (1-4) | `priority` (1=urgent, 2=high, 3=medium, 4=low) |
| Labels | `labels[]` |
| Estimate | `points` |

**Local owns** (never overwritten from Linear):

- `outcome`, `scope`, `acceptance_criteria`, `use_cases`, `notes` — the spec
- `blocked_by`, `blocking` — local dependency graph
- `id`, `slug` — local identifiers
- `branch`, `pr` — set by implementation workflow

## Process

### 1. Read local state

Read `./plans/{slug}/prd.yaml` and all `./plans/{slug}/issues/*.yaml`.

Verify `prd.yaml` has `linear.project_id`. If not, tell the user: "This plan hasn't been synced to Linear yet. Run `/sync-plan-to-linear` first."

Resolve the team in priority order:

1. User-provided team argument (highest priority)
2. `linear.team_key` in `prd.yaml`
3. `team_id` from `.linear.toml` (checked at repo root and standard config paths)
4. `linear team list` — use directly if one team, ask the user if multiple

Write the resolved `team_key` back to `prd.yaml` if it changed or was missing.

Build a lookup map: `linear_id` → local file path.

### 2. Fetch linked issues from Linear

For each local issue that has `linear_id`:

```bash
linear issue view {issue_id} --json
```

Parse the JSON to extract: state name, assignee, priority, labels, estimate.

### 3. Discover new Linear issues

List all issues in the Linear project to find ones created directly in Linear that have no local YAML:

```bash
linear issue list --project "{project_name}" --all-states --all-assignees --limit 0 --no-pager
```

Or use `linear issue view {id} --json` on each. Any issue identifier not in the local lookup map is new.

### 4. Build the change report

For each existing local issue, compare Linear state against local YAML. Track changes per file:

```text
issues/3-add-validation.yaml:
  status: todo → done
  assignee: null → jason
  points: 3 → 5
```

For new issues found in Linear, note them separately.

### 5. Present changes and confirm

Show the full change report to the user. Ask for confirmation before writing.

If no changes detected, report "Local plan is up to date with Linear" and stop.

### 6. Update existing issue files

For each changed issue, update only the Linear-owned fields in the YAML. Always update the `updated` date.

### 7. Create local files for new Linear issues

For each new issue discovered in Linear:

- Assign the next sequential local `id` (max existing id + 1)
- Generate a `slug` from the issue title (kebab-case)
- Create `{id}-{slug}.yaml` with all fields populated from Linear
- Set `outcome` and `scope` from the Linear issue description (parse the markdown sections if they follow the standard format, otherwise put the full description in `outcome`)
- Set `acceptance_criteria` from parsed checkbox items, or leave empty
- Write `linear_id` and `linear_url`

### 8. Sync PRD project status

Fetch the project status from Linear. Map to local PRD status:

| Linear project status | Local `status` |
|---|---|
| planned / backlog | draft |
| started / paused | active |
| completed | complete |
| canceled | archived |

Update `prd.yaml` if changed.

### 9. Report

```text
Plan: {project name}
Issues updated: {count} ({list of changes})
New issues imported: {count} ({list of new file paths})
PRD status: {old} → {new} (or "unchanged")
```
