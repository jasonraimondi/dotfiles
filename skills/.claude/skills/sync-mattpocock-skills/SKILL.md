---
name: sync-mattpocock-skills
description: Pull upstream changes from mattpocock/skills into the vendored copies in this repo, keeping local divergences.
disable-model-invocation: true
---

Sync the skills in [manifest.md](manifest.md) with `https://github.com/mattpocock/skills`. The manifest owns the local-to-upstream mapping, the divergences kept on purpose, and the last-synced commit.

## 1. Fetch

Clone upstream with full history into the scratchpad: `git clone --filter=blob:none https://github.com/mattpocock/skills <scratchpad>/mp`. Upstream nests skills by bucket and moves them when they graduate, so resolve each manifest row by skill name when its upstream path is missing.

## 2. Classify drift

For each manifest row, `diff -r` the upstream folder against the local one, then subtract the row's listed divergences and the invocation invariant below. What remains is **drift**. Read `git log <last-synced>..origin/main` and the `.changeset/` and `CHANGELOG.md` entries for the intent behind each drift.

Also report, without acting:

- **Removed** upstream skills still held locally.
- **New** upstream skills with no manifest row, grouped by upstream bucket, each with its one-line description.
- **Moved or renamed** skills.

Stop here and present the report: per skill, the drift and the upstream reason. The user picks what to take.

## 3. Apply

For each skill taken, copy the upstream files over the local folder, then reapply that row's divergences and the invocation invariant. A divergence that no longer applies upstream (the change landed there) comes out of the manifest.

**Invocation invariant**: everything lives in `vendor-mattpocock/`, and `setup.sh` leaves its frontmatter alone, so each skill keeps the invocation choice it has locally. User-invoked skills (`grill-me`, `grill-with-docs`, `retro`, `teach`, `to-questionnaire`, `wait-what`, `wizard`) carry `disable-model-invocation: true` in `SKILL.md` and `policy.allow_implicit_invocation: false` in `agents/openai.yaml`. The rest carry neither. Upstream's own invocation choice never overrides the local one.

Rewrite operative skill-to-skill references to local names where they differ (upstream `code-review` is `review-code` here).

A new skill goes in `vendor-mattpocock/` with its invocation choice set in the frontmatter, and a new manifest row.

## 4. Record

Update the manifest: last-synced commit, new rows, retired divergences. Done when a second diff pass shows drift only for skills the user declined, and `./setup.sh --dry-run` reports no name collisions or errors. Leave committing to the user.
