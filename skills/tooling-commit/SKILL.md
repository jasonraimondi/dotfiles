---
name: tooling-commit
description: Suggest a conventional commit message for the current staged/unstaged changes. Use when the user asks to commit, wants a commit message, says "commit", or wants to stage and commit code changes.
---

# Commit Message Generator

## Workflow

1. Use context already in the conversation window if sufficient. Otherwise, run `git diff` and `git diff --cached` to understand the changes.
2. Output the suggested message in a markdown code block — nothing else.
3. Use the conventional commits format: `type(scope): description` with an optional body.
4. Never commit `.idea/` changes automatically.
5. **Do NOT run `git commit` unless explicitly told to actually commit.**

BE CONCISE. BE IDIOMATIC.

## Argument Handling

If the user says "wip", add a `[WIP]` prefix to the message.

If the user says "really" or explicitly asks to commit, run `git commit` with the suggested message. Otherwise, only display the suggestion.
