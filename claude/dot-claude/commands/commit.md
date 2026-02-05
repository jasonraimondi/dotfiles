---
description: Suggest a conventional commit message for the current staged/unstaged changes.
---

Suggest a conventional commit message for the current staged/unstaged changes.

1. Use context already in the conversation window if sufficient. Otherwise, run `git diff` and `git diff --cached` to understand the changes.
2. Output the suggested message in a markdown code block — nothing else.
3. Use the conventional commits format: `type(scope): description` with an optional body.
4. Never commit .idea/ changes automatically.
5. **Do NOT run `git commit` unless the argument below is "commit".**

BE CONCISE. BE IDIOMATIC.

$ARGUMENTS

If the arguments contain "wip", make sure to add a `[WIP]` prefix to the message.
 
If the arguments contain "really" run `git commit` with the suggested message. Otherwise, only display the suggestion.
