---
name: css
description: Produce idiomatic, browser-aware modern CSS with progressive-enhancement fallbacks for vanilla CSS and Svelte styling tasks. Use for layout, spacing, typography, color/theming, responsive/container-query work, selector/specificity cleanup, interactive UI styling, and motion design — transitions, keyframes, `linear()` easing, transform strategy, View Transitions choreography — plus browser-support lookups (tier, `bcd_id`, `@supports` fallbacks) for any CSS feature.
---

# CSS Best Practices

Replace outdated styling patterns with idiomatic, accessible, performance-aware CSS.

## Defaults

- **Compatibility:** Baseline (Tier A only) unless user requests Progressive or Experimental.
- **Recommendations:** one primary solution per problem — no competing options.

## Workflow

1. **Classify** — name the styling domain (layout, motion, theme, selectors, interactive, typography, workflow/architecture) and constraints (browser support, a11y, framework).
2. **Load context** — read `preferences/index.md` first (token-driven, scope-local, cascade-first defaults). Then `references/index.md` to find the matching profile and **only** the relevant rule files in `references/rules/`. For motion, add `references/motion/index.md`.
3. **Match tier** — confirm each rule's `tier` matches the active compatibility mode. Use `bcd_id` and `mdn_url` from rule frontmatter for any user-facing support claims.
4. **Implement** — make the change. For B/C features, include an `@supports` fallback that preserves a usable Tier A baseline.
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

For B/C features: keep a robust Tier A baseline and layer enhancements with `@supports`.

## Core Principles

Topical map of the rules in `preferences/index.md`. The preferences file (and individual rule files) are authoritative on conflicts.

1. **Cascade** — `@layer` ordering, `:where()`/class selectors, avoid `!important`.
2. **Tokens** — every color, size, shadow, space is a `var(--*)`; centralize at `:root`, override per component.
3. **Variants** — override the custom property downstream properties already read; don't restyle the surface.
4. **Layout** — intrinsic first (`gap`, `aspect-ratio`, Grid/Flex, `auto-fit`, `minmax`, `clamp`); container queries when component size is the constraint, media queries when the viewport is.
5. **Logical properties** — `margin-inline`, `padding-block`, `inset-inline` over physical directions.
6. **Animation** — transform/opacity-based motion, `prefers-reduced-motion`, no JS-driven style hacks. Motion design, easing systems, and View Transitions choreography live in `references/motion/`; the `animation-*` rule files carry per-feature tier and compatibility data.
7. **Accessibility** — preserve `:focus-visible`, keyboard semantics; never trade a11y for visuals.
8. **Architecture** — `@scope`, nesting, `@property` with `inherits: false` for component-local primitives.
9. **Readability** — limit deep selector chains, avoid unnecessary nesting.

## Framework Output

When user requests **Svelte**: use `<style>` blocks (scoped by default), reach for `:global()` only when necessary. Follow the project's existing Svelte styling conventions.

## Output Format

When editing files, make the change and name the compatibility mode, tier, and any fallback in a sentence. When the request is for advice or a review without an edit, answer in this shape:

1. **Recommendation** — one concise modern replacement
2. **Why** — maintainability/perf/a11y benefit in 1–2 lines
3. **Compatibility** — mode + tier
4. **Fallback** — required for B/C, optional for A
5. **Code patch** — copy-paste ready

## References

- `preferences/index.md` — author preferences (token-driven, scope-local, cascade-first); load first
- `references/index.md` — rule map and quick search commands
- `references/profiles/` — `stable.md` (A), `progressive.md` (B), `experimental.md` (C)
- `references/css-techniques-guide.md` — full catalog with before/after examples
- `references/rules/` — per-technique files with `tier`, `bcd_id`, `mdn_url`, and caveats
- `references/motion/` — motion design: `index.md`, `linear-easing.md`, `view-transitions.md`, `tokens.css`, `disney-principles.md`

## Anti-Patterns

- Recommending B/C features without a Tier A fallback
- Using snapshot `%` support values as sole evidence for production readiness
- Introducing `!important` or deep specificity chains without necessity
- Returning style advice without concrete patch-level code
- Outputting framework-specific syntax when user asked for plain CSS
- Loading rule files the task doesn't need
