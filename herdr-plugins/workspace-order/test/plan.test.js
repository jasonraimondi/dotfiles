import assert from "node:assert/strict";
import { test } from "node:test";
import { planMove } from "../src/plan.js";

const REPO = "/r/.git";
const plain = (id) => ({ workspace_id: id });
const parent = (id) => ({ workspace_id: id, worktree: { repo_key: REPO, is_linked_worktree: false } });
const child = (id) => ({ workspace_id: id, worktree: { repo_key: REPO, is_linked_worktree: true } });

const sidebar = [plain("a"), parent("p"), child("c1"), child("c2"), plain("z")];

test("a plain workspace moves down past a whole worktree group", () => {
  const plan = planMove([plain("a"), parent("p"), child("c1"), plain("z")], "a", 1);
  assert.deepEqual(plan, { workspace_ids: ["a"], before_workspace_id: "z" });
});

test("a plain workspace moves up before the first member of the group above", () => {
  const plan = planMove([parent("p"), child("c1"), plain("z")], "z", -1);
  assert.deepEqual(plan, { workspace_ids: ["z"], before_workspace_id: "p" });
});

test("a worktree parent carries its children when moving down", () => {
  const plan = planMove(sidebar, "p", 1);
  assert.deepEqual(plan, { workspace_ids: ["p", "c1", "c2"], before_workspace_id: null });
});

test("a worktree child moves down past its next sibling only", () => {
  const plan = planMove(sidebar, "c1", 1);
  assert.deepEqual(plan, { workspace_ids: ["c1"], before_workspace_id: "z" });
});

test("a worktree child moves up before its previous sibling", () => {
  const plan = planMove(sidebar, "c2", -1);
  assert.deepEqual(plan, { workspace_ids: ["c2"], before_workspace_id: "c1" });
});

test("the first child cannot move up out of its group", () => {
  assert.equal(planMove(sidebar, "c1", -1), null);
});

test("the first workspace cannot move up", () => {
  assert.equal(planMove(sidebar, "a", -1), null);
});
