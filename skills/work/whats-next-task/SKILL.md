---
name: whats-next-task
description: Sweep Slack for open asks, then check Linear for what's already tracked, and rank what Jason should work on next. Use for "what should I work on next" or catching up after time away.
disable-model-invocation: true
---

# What's next

Slack carries the **open asks** — requests aimed at Jason that nobody has closed out. Linear is the **ledger** — what is already written down and assigned. Slack leads because new work lands there first; the ledger follows to say whether an ask is already on the books.

## 1. Window

Default window: the last 3 days. Use whatever window Jason names instead. Every search and the ledger lookup use that same window.

## 2. Sweep Slack

Jason's own activity is the map. Every conversation he posted in during the window is a live front, and the asks aimed at him sit in those threads or in his DMs.

Batch these searches, each with `after:<window start>` and `sort="timestamp"`:

- `from:me` — every channel, DM, and thread Jason posted in
- `to:me` — DMs and group DMs
- `jason` as a plain keyword — channel mentions, which `to:` does not match

`from:me` and `to:me` usually resolve on their own. On zero results, get Jason's ID with `slack_search_users` and search `from:<@U…>`.

## 3. Close what is already closed

Read every candidate in context before it counts — `slack_read_thread` on the thread, `slack_read_channel` around a loose message. Read forward to the last message: a `from:me` hit means Jason spoke, not that he finished, and whatever came after his last word is where the open ask lives.

An ask is **closed** when Jason already answered it, someone else picked it up, or the thread landed on a resolution. What survives is an open ask.

Done when every conversation the sweep returned has been read to its last message.

## 4. Check the ledger

- `list_issues` with assignee `me` and state started, then unstarted — what is already assigned to Jason
- `list_issues` with `updatedAt: -P<window in days>D` plus query terms drawn from the open asks

Mark each open ask **tracked** (name the identifier) or **untracked**.

## 5. Report

Ranked, one line per item, extremely concise. Link the Slack source and, if tracked, the Linear identifier — each to its permalink/URL when one was returned by the search or lookup:

```
- [ ] (untracked) [Checkout race on discount stacking](slack://...) — Lucy, DM, Tue
- [ ] [[INT-482](https://linear.app/...)] Review Pietro's migration plan — [#eng-platform](slack://...), Wed
- [ ] [[INT-455](https://linear.app/...)] Rate limiter rollout — assigned, in progress, no Slack activity
```

Rank by: someone waiting on a direct reply from Jason first, then asks blocking someone else, then explicit deadlines, then everything else. Within a tier, the most recent message wins. Assigned Linear work with no Slack traffic sorts last.

## 6. Log the day

Append today's ranked list to `plans/billing-shift/<today's date, YYYY-MM-DD>.md` in the notebook vault (`${AI_NOTEBOOK_PATH:-$HOME/Notebook}`) — same lines as the report, links included. Create the file with a `# <date>` heading if it doesn't exist yet. Never write to, or open for editing, any other date's file.

Re-running later the same day appends only items not already in today's file (match by Slack/Linear link, not by wording); it never touches an item already logged.

End on the list. Jason picks what to start.
