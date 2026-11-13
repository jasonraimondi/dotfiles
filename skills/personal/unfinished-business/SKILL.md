---
name: unfinished-business
description: Check for unfinished business
disable-model-invocation: true
---

Audit this session for unfinished business: anything asked of you, promised by you, or started by you that has no evidence of being done.

1. **Ledger.** Walk the session from the first message and enter every ask, every promise you made ("I'll also…", "next I'll…"), and everything you started: edits, commits, background tasks, subagents, scratch files. Done when the last message is entered.
2. **Close.** Close an entry only on evidence you observe now: `git status`, a test run, the task list, the file itself. An entry you remember finishing stays open until you look. Done when every entry has been checked.
3. **Report.** First line: `Finished` or `N open`. Then only the open entries, one line each, written as the next action and whether it is yours to do or waits on the user.
