// A worktree parent owns every linked worktree of its repo; they move as one unit.
// A linked worktree moves only among its linked siblings.

function buildUnits(workspaces) {
  const parentRepos = new Set(
    workspaces.filter((w) => w.worktree && !w.worktree.is_linked_worktree).map((w) => w.worktree.repo_key),
  );
  const units = [];
  const byRepo = new Map();
  for (const w of workspaces) {
    const repo = w.worktree?.repo_key;
    if (repo && parentRepos.has(repo)) {
      if (!byRepo.has(repo)) {
        const unit = [];
        byRepo.set(repo, unit);
        units.push(unit);
      }
      byRepo.get(repo).push(w.workspace_id);
    } else {
      units.push([w.workspace_id]);
    }
  }
  return units;
}

function moveBlock(blockIds, targetIds, delta, order) {
  const targetPos = order.indexOf(targetIds[delta < 0 ? 0 : targetIds.length - 1]);
  const before = delta < 0 ? order[order.indexOf(targetIds[0])] : (order[targetPos + 1] ?? null);
  return { workspace_ids: blockIds, before_workspace_id: before };
}

export function planMove(workspaces, workspaceId, delta) {
  const order = workspaces.map((w) => w.workspace_id);
  const current = workspaces.find((w) => w.workspace_id === workspaceId);
  if (!current) return null;

  if (current.worktree?.is_linked_worktree) {
    const siblings = workspaces
      .filter((w) => w.worktree?.is_linked_worktree && w.worktree.repo_key === current.worktree.repo_key)
      .map((w) => w.workspace_id);
    const target = siblings[siblings.indexOf(workspaceId) + delta];
    return target ? moveBlock([workspaceId], [target], delta, order) : null;
  }

  const units = buildUnits(workspaces);
  const at = units.findIndex((u) => u.includes(workspaceId));
  const target = units[at + delta];
  if (!target) return null;
  const block = [...units[at]].sort((a, b) => order.indexOf(a) - order.indexOf(b));
  const anchorUnit = delta < 0 ? target : units[at + 2];
  return {
    workspace_ids: block,
    before_workspace_id: anchorUnit ? anchorUnit[0] : null,
  };
}
