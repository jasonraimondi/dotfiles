---
name: report-for-standup
description: Turn recent work into standup bullets.
disable-model-invocation: true
---

# Report for standup

Jason reads this aloud at standup. Write for the listeners, not for Jason — non-technical readers must follow it without asking what a word means.

Source: the work in this conversation. If the conversation carries none, use `git log --author=jason --since=yesterday` across the repo.

Talk in ASD-STE100 Simplified Technical English. Use the ubiquitous language from `GLOSSARY.md` if it exists.

Sacrifice grammar for concision.

## Format

One block per topic: a short heading, then a few terse bullets. The report is read aloud in about a minute, so when more topics were touched than fit, keep the ones the listeners most need.

```
Checkout discount stacking
- Race found. Two discounts applied together.
- Fix written. In review.
- Ships tomorrow.
```

Done when every topic the listeners need has a block.
