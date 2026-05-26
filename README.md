# skills

A personal collection of [Agent Skills](https://www.anthropic.com/news/skills) — portable, model-invoked instruction packs for Claude Code, Pi, and any other tool that speaks the Anthropic `SKILL.md` format.

Each skill is a single folder containing a `SKILL.md` (YAML frontmatter + body) and optional `references/`. Agents discover skills by name and load the body on demand, so adding a new skill is just dropping a new folder in.

The repo splits skills into two roots:

- [`skills/`](./skills) — skills I wrote and maintain
- [`vendor/`](./vendor) — skills downloaded from other public repos via [`add-skill.sh`](./add-skill.sh)

Both roots are agent-equivalent. The split is purely about provenance: `vendor/` content can be re-synced or replaced wholesale, `skills/` content is mine to edit.

> [!NOTE]
> Skills are model-invoked, not human-invoked. An agent loads a skill when its `description` matches the task at hand — write the description so future-you (or a model) can tell when it applies.

## Install

Clone the repo wherever you keep tools, then use [`setup.sh`](./setup.sh) to wire per-skill symlinks into Claude Code and Pi (both roots get linked):

```sh
git clone git@github.com:jasonraimondi/skills.git ~/Code/skills
cd ~/Code/skills
./setup.sh             # link everything
./setup.sh --dry-run   # preview without touching the filesystem
./setup.sh --delete    # remove the symlinks this script created
```

`setup.sh` walks both `./skills/` and `./vendor/` and links each individual skill into `~/.claude/skills/` and `~/.pi/agent/skills/`. On name collision, personal wins.

> [!TIP]
> Drop the repo into any directory you frequently open with an agent and the skills come along with it. No package install, no build step.

The script also wires the shared `AGENT.md` from this repo into the rule/memory locations Claude Code, Cursor, Windsurf, Junie, and Pi each look for. Safe to skip if you don't keep your AI config there.

## Mine

| Skill | Use for |
| --- | --- |
| [`best-practices-codebase-architecture`](./skills/best-practices-codebase-architecture) | Finding refactors that deepen shallow modules and improve testability |
| [`best-practices-comments`](./skills/best-practices-comments) | Auditing and removing journal/noise/redundant code comments |
| [`best-practices-css`](./skills/best-practices-css) | Idiomatic modern CSS with progressive-enhancement fallbacks |
| [`best-practices-html`](./skills/best-practices-html) | Semantic HTML/Svelte markup, landmarks, forms, native controls |
| [`best-practices-oidc`](./skills/best-practices-oidc) | OIDC/OAuth 2.0 flows, token validation, endpoints, security hardening |
| [`best-practices-svelte5`](./skills/best-practices-svelte5) | Authoring Svelte 5 components and SvelteKit apps |
| [`frontend-oklch`](./skills/frontend-oklch) | OKLCH conversions, palettes, contrast, gamut handling |
| [`pr-description-template`](./skills/pr-description-template) | Rewriting PR titles/bodies to a conventional-commits + JIRA template |
| [`review-code`](./skills/review-code) | Unified code review with seven modes — `full`, `security`, `architecture`, `merge-risk`, `adversarial`, `caveman`, `multi` (seven-reviewer parallel + verifier). Invoke as `/review-code <mode> [<scope>]` |

## Vendored

Skills sourced from other public repos. Re-sync with [`add-skill.sh`](./add-skill.sh).

### Best practices

| Skill | Use for |
| --- | --- |
| [`best-practices-better-auth`](./vendor/best-practices-better-auth) | Integrating the Better Auth TypeScript framework |
| [`best-practices-golang`](./vendor/best-practices-golang) | Concurrent Go, microservices, generics, table-driven tests |
| [`best-practices-rust`](./vendor/best-practices-rust) | Idiomatic Rust based on Apollo's handbook |
| [`best-practices-stripe`](./vendor/best-practices-stripe) | Stripe integration decisions across Checkout, Connect, Billing, Treasury |
| [`best-practices-tailwind`](./vendor/best-practices-tailwind) | Utility-first Tailwind composition aligned to design tokens |

### Design & frontend

| Skill | Use for |
| --- | --- |
| [`css-motion-systems`](./vendor/css-motion-systems) | CSS motion design, `linear()` easing, View Transitions, Disney principles |
| [`design-interface`](./vendor/design-interface) | Generating multiple radically different API/module shapes in parallel |
| [`design-state-machine`](./vendor/design-state-machine) | Statechart and state-machine lifecycle modeling |
| [`impeccable`](./vendor/impeccable) | UX/UI critique, polish, and ambitious frontend redesign |
| [`prototype`](./vendor/prototype) | Throwaway prototypes for state machines or UI variations |

### Git & commits

| Skill | Use for |
| --- | --- |
| [`review-caveman`](./vendor/review-caveman) | Ultra-blunt cross-cutting review (style for PR or local diffs) |
| [`git-commit-caveman`](./vendor/git-commit-caveman) | Ultra-compressed Conventional Commits messages |
| [`git-commit-full`](./vendor/git-commit-full) | Full conventional-commit workflow with intelligent staging |
| [`my-pull-requests`](./vendor/my-pull-requests) | Listing the PRs assigned to me in the current repo |

### Testing & debugging

| Skill | Use for |
| --- | --- |
| [`diagnose`](./vendor/diagnose) | Disciplined reproduce → minimise → hypothesise → fix loop for hard bugs and perf regressions |
| [`testing-tdd`](./vendor/testing-tdd) | Red-green-refactor TDD loop, integration-test-first |
| [`testing-vitest`](./vendor/testing-vitest) | Vitest setup, mocking, coverage, filtering |

### Tooling

| Skill | Use for |
| --- | --- |
| [`gh-cli`](./vendor/gh-cli) | GitHub CLI reference for repos, PRs, Actions, releases |
| [`tooling-agent-browser`](./vendor/tooling-agent-browser) | Browser automation CLI for navigating, scraping, testing |
| [`tooling-image-magick`](./vendor/tooling-image-magick) | ImageMagick resizing, conversion, batch processing |
| [`tooling-linear-cli`](./vendor/tooling-linear-cli) | Managing Linear issues from the command line |
| [`tooling-pnpm`](./vendor/tooling-pnpm) | pnpm workspaces, catalogs, patches, overrides |

### Language deep-dives

| Skill | Use for |
| --- | --- |
| [`typescript-advanced-types`](./vendor/typescript-advanced-types) | Generics, conditional/mapped types, template literals, utilities |

### Writing & meta

| Skill | Use for |
| --- | --- |
| [`code-simplifier`](./vendor/code-simplifier) | Refining code for clarity while preserving behavior |
| [`handoff`](./vendor/handoff) | Compacting the current conversation into a handoff doc for another agent |
| [`karpathy-guidelines`](./vendor/karpathy-guidelines) | Behavioral guardrails to reduce common LLM coding mistakes |
| [`meta-write-a-skill`](./vendor/meta-write-a-skill) | Authoring new skills with progressive disclosure |
| [`writing-copy`](./vendor/writing-copy) | Marketing/landing/feature page copy |
| [`writing-readme`](./vendor/writing-readme) | Authoring project READMEs (this one was built with it) |
| [`writing-strip-ai`](./vendor/writing-strip-ai) | Strip AI-sounding patterns from a draft |

## Anatomy of a skill

```
skills/<skill-name>/        # or vendor/<skill-name>/
├── SKILL.md                # required: frontmatter + body
└── references/             # optional: deeper docs the body links to
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

For something you wrote yourself:

1. Create a folder under [`skills/`](./skills) named in `kebab-case`.
2. Add a `SKILL.md` with `name` and `description` frontmatter.
3. Restart your agent session (or rescan) so the new skill is picked up.

The [`meta-write-a-skill`](./vendor/meta-write-a-skill) skill walks through this end-to-end if you'd rather have an agent draft it.

For pulling a skill from another public repo, use [`add-skill.sh`](./add-skill.sh):

```sh
./add-skill.sh add https://github.com/anthropics/skills --skill frontend-design
```

It lands under `./vendor/<name>/`. The source folder is resolved by trying
`skills/<name>`, `.gemini/skills/<name>`, `.claude/skills/<name>`, then any
`skills/*/<name>` — pass `--path <subpath>` to point at it explicitly.
