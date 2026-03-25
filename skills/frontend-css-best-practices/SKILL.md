---
name: frontend-css-best-practices
description: Produce idiomatic, browser-aware modern CSS with progressive-enhancement fallbacks for CSS, Tailwind, and Svelte styling tasks. Use for layout, spacing, typography, color/theming, animation, responsive/container-query work, selector/specificity cleanup, and interactive UI styling. Do not use for non-styling business logic or design critique without code edits.
---

# CSS Best Practices

Replace outdated styling patterns with idiomatic, accessible, performance-aware CSS.

## Defaults

- **Output:** vanilla CSS unless user requests Tailwind or Svelte syntax.
- **Compatibility:** Baseline (Tier A only) unless user requests Progressive or Experimental.
- **Recommendations:** one primary solution per problem — no competing options.

## Workflow

1. **Classify** — determine the styling domain (layout, motion, theme, selectors, interactive, typography, workflow/architecture) and constraints (browser support, a11y, framework).
2. **Load references** — read `references/index.md`, then the matching profile and **only** the relevant rule files from `references/rules/`. Load at most 5 rule files per task.
3. **Match tier** — confirm each rule's `tier` matches the active compatibility mode. Use `bcd_id` and `mdn_url` from rule frontmatter for any user-facing support claims.
4. **Implement** — provide a patch-level code change. For B/C features, include an `@supports` fallback that preserves a usable baseline.
5. **Quality check:**
   - No a11y regressions
   - No unnecessary specificity escalation
   - No avoidable JS workaround when native CSS works
   - Motion respects `prefers-reduced-motion`

## Compatibility Modes

| Mode | Tiers | When |
|---|---|---|
| **Baseline** (default) | A (`>=90%`) | Production-safe, unknown browser matrix |
| **Progressive** | A + B (`80–89%`) | User accepts fallbacks |
| **Experimental** | A + B + C (`<80%`) | User explicitly asks for cutting-edge |

For B/C features: always keep a robust Tier A baseline and layer enhancements with `@supports`.

## Idiomatic CSS Principles

1. **Cascade** — `@layer` ordering, `:where()`/class selectors, avoid `!important`.
2. **Tokens** — centralize values as custom properties; no hardcoded magic numbers.
3. **Logical properties** — `margin-inline`, `padding-block`, `inset-inline` over physical directions.
4. **Layout** — `gap`, `aspect-ratio`, Grid/Flex, container queries, `subgrid`, `inset`.
5. **Animation** — transform/opacity-based motion, `prefers-reduced-motion`, no JS-driven style hacks.
6. **Accessibility** — preserve `:focus-visible`, keyboard semantics; never trade a11y for visuals.
7. **Architecture** — `@scope`, nesting, `@property` for typed custom properties; keep component styles local.
8. **Readability** — limit deep selector chains, avoid unnecessary nesting.

## Framework Output

When user requests **Tailwind**: use utility classes, respect the project's Tailwind config, prefer `@apply` sparingly. Map CSS rules to their Tailwind equivalents.

When user requests **Svelte**: use `<style>` blocks (scoped by default), leverage Svelte's `:global()` only when necessary. Follow the project's existing Svelte styling conventions.

## Output Format

1. **Recommendation** — one concise modern replacement
2. **Why** — maintainability/perf/a11y benefit in 1–2 lines
3. **Compatibility** — mode + tier
4. **Fallback** — required for B/C, optional for A
5. **Code patch** — copy-paste ready

## References

- `references/index.md` — entrypoint, rule map, quick search commands
- `references/profiles/` — `stable.md` (A), `progressive.md` (B), `experimental.md` (C)
- `references/css-techniques-guide.md` — full catalog with before/after examples
- `references/rules/` — per-technique rule files with `tier`, `bcd_id`, `mdn_url`, and caveats

## Anti-Patterns

- Recommending B/C features without a Tier A fallback
- Using snapshot `%` support values as sole evidence for production readiness
- Introducing `!important` or deep specificity chains without necessity
- Returning style advice without concrete patch-level code
- Outputting framework-specific syntax when user asked for plain CSS
- Loading more rule files than needed — stay within 5 per task
