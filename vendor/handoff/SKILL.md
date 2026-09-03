---
name: handoff
description: Write the current conversation into a standalone handoff document for a human or agent to pick up later.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Name the file `{YYYY-MM-DD}-{HHMM}-{short_description}.md`, where `HHMM` is the current local 24-hour time (e.g. `2026-08-31-2304-billing_escalations.md`) — run `date +%Y-%m-%d-%H%M` to get the stamp; never guess it. If the project's instructions designate a directory for handoff documents, save it there under that name; otherwise save it to a path produced by `mktemp -t handoff-{YYYY-MM-DD}-{HHMM}-{short_description}.md`. Claude must read the file before attempting to write to it.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
