---
name: cleanup-worktrees
description: Inspect worktrees, check ticket-based work against Linear, and safely remove eligible worktrees.
disable-model-invocation: true
---

# Clean up worktrees

1. From the repository, run `git worktree list --porcelain` and `git worktree prune --dry-run --verbose`. Inventory all worktrees, including path, branch, and lock/prunable state. Keep the main and current worktrees out of the removal set. If there are no linked worktrees, report that and stop.
2. Split the inventory into ticket-based and non-ticket worktrees. Extract a Linear identifier such as `INT-123` from the worktree basename or branch; if they disagree or the match is ambiguous, keep it out of the removal set. Protect worktrees whose basename or branch ends in `-shift`, `-spike`, `-billing`, or `-<teammate-name>`, even if ticket-based or marked done. Ask for the teammate names when they are not known; until then, treat uncertain suffixes as protected. Show these protected worktrees in the inventory, not in cleanup candidates.
3. For every unprotected ticket-based worktree, look up its issue by exact identifier in Linear using the `linear-cli` skill. Record the issue title and status. Only a confirmed **completed** issue qualifies as done; canceled, missing, inaccessible, or uncertain issues stay out of the removal set. Non-ticket worktrees are listed but not selected automatically.
4. For each potential removal, inspect `git -C <path> status --short --branch` and check whether an agent or process is still using it. Worktrees with uncommitted or untracked files, locks, or active users are protected. A merged branch by itself is not evidence that its worktree is disposable.
5. Present the full inventory grouped by ticket-based, non-ticket, and protected worktrees, with Linear status and local safety checks where applicable. Propose only completed, clean, unlocked, inactive ticket-based worktrees for removal. Ask the user to confirm the exact paths to remove and whether to prune stale administrative entries.
6. After confirmation, recheck the selected paths, protection rules, issue statuses, and local state. Remove only still-eligible linked worktrees with `git worktree remove <path>`; skip and report any that changed. Run `git worktree prune` only if confirmed, and report what it pruned. Leave branches intact unless the user separately requests branch deletion.
7. Run `git worktree list --porcelain` again and report removed paths and remaining worktrees needing attention.

Use Git worktree commands rather than deleting worktree directories directly. Avoid `--force`, `rm -rf`, and automatic branch deletion; when a requested cleanup requires one of those, explain the risk and get a separate explicit decision.
