---
name: my-pull-requests
description: 'List my pull requests in the current repository'
disable-model-invocation: true
---

List the open pull requests in the current repo that are assigned to me (`gh pr list --assignee @me`).

Describe the purpose and details of each pull request.

If a PR is waiting for someone to review, highlight that in the response.

If there were any check failures on the PR, describe them and suggest possible fixes.
