# skills

A personal collection of [Agent Skills](https://www.anthropic.com/news/skills) — portable, model-invoked instruction packs for Claude Code, Pi, and any other tool that speaks the Anthropic `SKILL.md` format.

Each skill is a single folder under [`skills/`](./skills) containing a `SKILL.md` (YAML frontmatter + body) and optional `references/`. Agents discover skills by name and load the body on demand, so adding a new skill is just dropping a new folder in.

> [!NOTE]
> Skills are model-invoked, not human-invoked. An agent loads a skill when its `description` matches the task at hand — write the description so future-you (or a model) can tell when it applies.

## Install

Clone the repo wherever you keep tools, then point your agent at it. The fastest path is a symlink from the agent's skills directory into [`skills/`](./skills):

```sh
git clone git@github.com:jasonraimondi/skills.git ~/Code/skills

# Claude Code (user-level skills)
ln -s ~/Code/skills/skills ~/.claude/skills

# Or per-project: symlink into your repo's .claude/ folder
ln -s ~/Code/skills/skills /path/to/repo/.claude/skills
```

The repo itself wires `.claude/skills` and `.pi/skills` as symlinks to [`skills/`](./skills), so cloning *into* an agent's working tree just works.

> [!TIP]
> Drop the repo into any directory you frequently open with an agent and the skills come along with it. No package install, no build step.

## What's inside

Thirty-plus skills, grouped by what they help you do.

### Best practices

| Skill | Use for |
| --- | --- |
| [`best-practices-better-auth`](./skills/best-practices-better-auth) | Integrating the Better Auth TypeScript framework |
| [`best-practices-codebase-architecture`](./skills/best-practices-codebase-architecture) | Finding refactors that deepen shallow modules and improve testability |
| [`best-practices-comments`](./skills/best-practices-comments) | Auditing and removing journal/noise/redundant code comments |
| [`best-practices-css`](./skills/best-practices-css) | Idiomatic modern CSS with progressive-enhancement fallbacks |
| [`best-practices-golang`](./skills/best-practices-golang) | Concurrent Go, microservices, generics, table-driven tests |
| [`best-practices-html`](./skills/best-practices-html) | Semantic HTML/Svelte markup, landmarks, forms, native controls |
| [`best-practices-rust`](./skills/best-practices-rust) | Idiomatic Rust based on Apollo's handbook |
| [`best-practices-svelte5`](./skills/best-practices-svelte5) | Authoring Svelte 5 components and SvelteKit apps |
| [`best-practices-tailwind`](./skills/best-practices-tailwind) | Utility-first Tailwind composition aligned to design tokens |

### Design & frontend

| Skill | Use for |
| --- | --- |
| [`css-motion-systems`](./skills/css-motion-systems) | CSS motion design, `linear()` easing, View Transitions, Disney principles |
| [`design-interface`](./skills/design-interface) | Generating multiple radically different API/module shapes in parallel |
| [`design-state-machine`](./skills/design-state-machine) | Statechart and state-machine lifecycle modeling |
| [`frontend-oklch`](./skills/frontend-oklch) | OKLCH conversions, palettes, contrast, gamut handling |
| [`impeccable`](./skills/impeccable) | UX/UI critique, polish, and ambitious frontend redesign |

### Pull requests & review

| Skill | Use for |
| --- | --- |
| [`pr-description-template`](./skills/pr-description-template) | Rewriting PR titles/bodies to a conventional-commits + JIRA template |
| [`pr-merge-risk`](./skills/pr-merge-risk) | Verdict-style merge-risk analysis with reversibility scoring |
| [`pr-review-caveman`](./skills/pr-review-caveman) | Ultra-blunt cross-cutting PR review |
| [`pr-review-full`](./skills/pr-review-full) | Single-pass review for correctness, security, and quality |
| [`pr-review-multi-agent`](./skills/pr-review-multi-agent) | Six-agent orchestrated deep review (5 reviewers + verifier) |
| [`pr-review-security`](./skills/pr-review-security) | OWASP-style security review with confidence-based reporting |

### Git & commits

| Skill | Use for |
| --- | --- |
| [`git-commit-caveman`](./skills/git-commit-caveman) | Ultra-compressed Conventional Commits messages |
| [`git-commit-full`](./skills/git-commit-full) | Full conventional-commit workflow with intelligent staging |

### Testing

| Skill | Use for |
| --- | --- |
| [`testing-tdd`](./skills/testing-tdd) | Red-green-refactor TDD loop, integration-test-first |
| [`testing-vitest`](./skills/testing-vitest) | Vitest setup, mocking, coverage, filtering |

### Tooling

| Skill | Use for |
| --- | --- |
| [`gh-cli`](./skills/gh-cli) | GitHub CLI reference for repos, PRs, Actions, releases |
| [`tooling-agent-browser`](./skills/tooling-agent-browser) | Browser automation CLI for navigating, scraping, testing |
| [`tooling-image-magick`](./skills/tooling-image-magick) | ImageMagick resizing, conversion, batch processing |
| [`tooling-linear-cli`](./skills/tooling-linear-cli) | Managing Linear issues from the command line |
| [`tooling-pnpm`](./skills/tooling-pnpm) | pnpm workspaces, catalogs, patches, overrides |

### Language deep-dives

| Skill | Use for |
| --- | --- |
| [`typescript-advanced-types`](./skills/typescript-advanced-types) | Generics, conditional/mapped types, template literals, utilities |

### Writing & meta

| Skill | Use for |
| --- | --- |
| [`code-simplifier`](./skills/code-simplifier) | Refining code for clarity while preserving behavior |
| [`karpathy-guidelines`](./skills/karpathy-guidelines) | Behavioral guardrails to reduce common LLM coding mistakes |
| [`meta-write-a-skill`](./skills/meta-write-a-skill) | Authoring new skills with progressive disclosure |
| [`writing-copy`](./skills/writing-copy) | Marketing/landing/feature page copy |
| [`writing-readme`](./skills/writing-readme) | Authoring project READMEs (this one was built with it) |

## Anatomy of a skill

```
skills/<skill-name>/
├── SKILL.md           # required: frontmatter + body
└── references/        # optional: deeper docs the body links to
```

`SKILL.md` starts with YAML frontmatter — the `description` is what the agent reads to decide whether to load the body:

```markdown
---
name: my-skill
description: One-sentence summary plus the trigger phrases that should activate this skill.
---

# Title

Body content the agent loads when the skill fires.
```

Keep descriptions concrete about *when* the skill applies. Vague descriptions get loaded too often or never; sharp ones route themselves.

## Adding a new skill

1. Create a folder under [`skills/`](./skills) named in `kebab-case`.
2. Add a `SKILL.md` with `name` and `description` frontmatter.
3. Restart your agent session (or rescan) so the new skill is picked up.

The [`meta-write-a-skill`](./skills/meta-write-a-skill) skill walks through this end-to-end if you'd rather have an agent draft it.

## External skills

[`skills-lock.json`](./skills-lock.json) tracks skills imported from other public repos along with a content hash, so a re-sync can detect drift. Current entries live in the lock file.
