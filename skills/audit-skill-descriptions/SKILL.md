---
name: audit-skill-descriptions
description: Audit every skill description in a folder against the context-pointer rules.
disable-model-invocation: true
---

Load `writing-for-agents`. For every `SKILL.md` under the given folder, grade its `description` on:

- leading word front-loaded
- one trigger per branch
- identity the body carries cut
- no collision with another skill's triggers

Done when every skill has a verdict and a proposed rewrite for each failure.
