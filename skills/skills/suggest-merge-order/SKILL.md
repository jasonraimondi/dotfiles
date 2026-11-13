---
name: suggest-merge-order
description: Suggest an order to merge my open PRs, weighing dependencies, conflicts, and any constraints I give.
disable-model-invocation: true
---

# Suggest merge order

Recommends a merge sequence for every open PR Jason authored or is assigned to. The output is a plan; merging, rebasing, and retargeting stay with Jason.

`{argument}` carries free-form **constraints**: filters ("no drafts", "only acme-org/app", "ignore the billing stack") and priorities ("low risk first", "get #6536 in today"). Constraints reshape the plan wherever they apply, with one exception: a **hard dependency** (a PR that cannot work or cannot merge before another) always holds. When a constraint would break one, follow the dependency and say which constraint lost and why. When a constraint names something you cannot match to a PR or stack, ask before going further.

## Workflow

1. **Collect.** Run `gh repo view --json nameWithOwner -q .nameWithOwner`. If it succeeds, the working directory is a GitHub repo: add `--repo <owner/repo>` to both searches below and treat that repo as the whole scope, unless a constraint asks for every repo. If it fails, search across all repos. Then run both searches and dedupe by `url` (GitHub's raw search API rejects `@me` inside an `OR`):

   ```sh
   gh search prs --state open --author @me --limit 100 --json number,title,url,repository,isDraft,author,assignees,labels,updatedAt
   gh search prs --state open --assignee @me --limit 100 --json number,title,url,repository,isDraft,author,assignees,labels,updatedAt
   ```

   A repo-scoped run skips the cross-repo dependency checks in step 3.

   Then for each PR: `gh pr view <n> -R <owner/repo> --json body,baseRefName,headRefName,mergeStateStatus,reviewDecision,statusCheckRollup,files,additions,deletions`.

2. **Filter.** Apply the filter constraints. Every PR removed lands in the excluded list with its reason. Done when every collected PR is either in scope or excluded.

3. **Map dependencies.** Within each repo, a PR whose `baseRefName` is another open PR's `headRefName` is stacked on it. Treat each stack as one unit that merges bottom-up. Also record dependencies the branches don't show: "depends on #N" or a shared ticket in a body, a PR consuming a function, endpoint, column, or package version another PR introduces, and cross-repo pairs (an API change before its client, a published package before its consumers). Step 4 surfaces most of the implicit ones.

4. **Understand each diff.** Every in-scope PR gets a **brief**: intent in one sentence; areas touched; interfaces it adds, changes, or removes; interfaces it consumes from other open PRs; schema migrations and other one-way doors; size and how mechanical the change is (rename, codemod, formatter, lockfile). Write it from `gh pr diff <n> -R <owner/repo>` plus the body. Above about 2000 diff lines, read the file headers and a few hunks per file, and mark the brief as sampled. With more than about six PRs, dispatch one subagent per PR (or per small stack) that returns only the brief, so the raw diffs stay out of your context. Done when every in-scope PR has a brief.

5. **Find conflicts.** For every pair in the same repo with overlapping `files`, decide whether merging one forces a painful rebase of the other. If the repo is cloned locally, test the pair directly:

   ```sh
   git fetch origin <headA> <headB>
   git merge-tree --write-tree --name-only origin/<headA> origin/<headB>
   ```

   A non-zero exit means they conflict, and the listed paths are where. Without a clone, judge from the overlapping hunks. Done when every overlapping pair has a verdict: clean, trivial, or painful (with the files).

6. **Order.** Unless the constraints reorder them, weigh three angles in this order:
   1. **Logic**: hard dependencies first, then foundations before what builds on them (refactors before the features that use them, migrations before code that reads the new shape, producers before consumers).
   2. **Conflict cost**: put the rebase burden on whichever PR is cheapest to carry it. A small focused PR rebases cheaply onto a large one. A mechanical PR is cheaper to regenerate than to rebase, so it goes after the PRs it collides with, unless they build on it.
   3. **Readiness**: among PRs still unordered, approved, green, `CLEAN` PRs go first. Drafts, failing checks, and requested changes go later and show as blockers.

   For a "risk" constraint, grade each PR by the reversibility tiers in [`../deep-review-code/lenses/merge-risk.md`](../deep-review-code/lenses/merge-risk.md).

7. **Report.** Print the plan in the shape below. Done when every collected PR appears exactly once.

## Report shape

Jason acts on the report, so it fits on one screen: about 25 lines for a dozen PRs. Briefs, conflict tests, and the dependency map are working notes. They reach the report only where they change what Jason does next.

```
Next: <one action to take now, with the deadline if there is one>

<facts true of every PR, said once: "Nothing is approved yet. All checks pass.">

## owner/repo
1. #6524 release unapproved trialing bridge. Then deploy and run `ig run billing resubmit-rejected-reinstall-releases`, dry run first.
2. #6525 Choose plan on a cancelled trial.
3. #6523 cancelled plan intent stops blocking creates. Goes before #6496 so its specs see the new behaviour.
4. #6496 plan source authority on reconciliations. Rebase onto #6523. Conflicts with #6534 in `shopify-execution-lane.ts`, about 5 lines.

## Not ready
- #6388 160 commits behind and its design predates #6183. Submit your pending review.
- notebox#56 conflicts with main and CI fails. Rebase and re-run CI.

## Any time
#6513, #6511, #6512

Excluded: #6559, #6562 (drafts).
```

- Each PR gets one line: the number, then the title with its conventional-commit prefix and ticket removed. Add at most one short sentence each for why it sits here, what blocks it, and what to run after it merges. Leave out a "why" that the stack order or the line above already explains.
- A PR goes under Not ready when it is a draft, conflicts with its base, fails checks, or needs rework. Give it one line with the blocker and the action that clears it.
- Leave out empty sections, routine stack retargeting, and how the plan was made. When a stack needs retargeting, end with one line pointing to the `gh-stack` skill.
- The report orders PRs. Code review findings belong to `/review-code`, so mention one only when it blocks the merge.
- Note a sampled diff or a conflict judged without a local clone on that PR's line, only when the placement depends on it.
- If a constraint lost to a hard dependency, say so on the affected PR's line.
