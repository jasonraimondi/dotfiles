---
name: whats-next-task
description: Sweep Slack for open asks, then check Linear for what's already tracked, and rank what Jason should work on next. Use for "what should I work on next", "what's on my plate", "look through my Slack for things I need to do", or catching up after time away.
disable-model-invocation: true
---

# What's next

Slack carries the **open asks** — requests aimed at Jason that nobody has closed out. Linear is the **ledger** — what is already written down and assigned. Slack leads because new work lands there first; the ledger follows to say whether an ask is already on the books.

## 1. Window and callouts

Default window: the last 3 days. Use whatever window Jason names instead.

**Callouts** — asks from these people outrank everything else: Lucy, Pietro, Emily, Angel, Christian, Adam.

## 2. Sweep Slack

Batch these searches, each with `after:<window start>` and `sort="timestamp"`:

- `to:me` — DMs and group DMs
- `jason` as a plain keyword — channel mentions, which `to:` does not match
- one search per callout name, `from:Lucy` and so on

`from:Lucy` usually resolves on its own. On zero results or a name shared by two people, get the ID with `slack_search_users` and search `from:<@U…>`.

## 3. Close what is already closed

Read every candidate in context before it counts — `slack_read_thread` on the thread, `slack_read_channel` around a loose message. An ask is **closed** when Jason already answered it, someone else picked it up, or the thread landed on a resolution. What survives is an open ask.

Done when every callout name has been searched and every candidate has been read in its thread.

## 4. Check the ledger

- `list_issues` with assignee `me` and state started, then unstarted — what is already assigned to Jason
- `list_issues` with `updatedAt: -P3D` (match the window) plus query terms drawn from the open asks

Mark each open ask **tracked** (name the identifier) or **untracked**.

## 5. Report

Ranked, one line per item, extremely concise:

```
1. (untracked) Checkout race on discount stacking — Lucy, DM, Tue
2. [INT-482] Review Pietro's migration plan — #eng-platform, Wed
3. [INT-455] Rate limiter rollout — assigned, in progress, no Slack activity
```

Rank by: callouts first, then asks blocking someone else, then explicit deadlines, then everything else. Assigned Linear work with no Slack traffic sorts last.

End on the list. Jason picks what to start.
