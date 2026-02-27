---
name: frontend-css-best-practices
description: Produce idiomatic, browser-aware modern CSS with progressive-enhancement fallbacks for CSS, Tailwind, and Svelte styling tasks. Use for layout, spacing, typography, color/theming, animation, responsive/container-query work, selector/specificity cleanup, and interactive UI styling. Do not use for non-styling business logic or design critique without code edits.
---

# CSS Best Practices

Replace outdated styling patterns with idiomatic, accessible, performance-aware CSS.

## Defaults

- **Output format:** vanilla CSS. Only output Tailwind/Svelte when user asks.
- **Compatibility mode:** Baseline (Tier A only).
- **Recommendations:** one primary solution, not competing options.

## Workflow

1. **Identify objective** — layout, motion, theme, selectors, etc. + constraints (browser support, a11y, framework).
2. **Select compatibility mode** — Baseline unless user requests Progressive or Experimental.
3. **Load references** — read `references/index.md`, then the matching profile and only relevant rule files from `references/rules/`.
4. **Verify support** — confirm rule `tier` matches mode. Use `mdn_url` and `bcd_id` from rule frontmatter; treat `browser` % as snapshot only.
5. **Implement** — provide a patch-level code change with `@supports` fallback for B/C features.
6. **Quality check** — no a11y regression, no unnecessary specificity escalation, no avoidable JS workaround, motion honors `prefers-reduced-motion`.

## Compatibility Modes

| Mode | Tiers | When |
|---|---|---|
| **Baseline** (default) | A (`>=90%`) | Production-safe, unknown browser matrix |
| **Progressive** | A + B (`80–89%`) | User accepts fallbacks |
| **Experimental** | A + B + C (`<80%`) | User explicitly asks for cutting-edge |

For B/C features, keep a robust baseline and layer enhancements with `@supports`.

## Idiomatic CSS Rules

1. **Cascade** — use `@layer` ordering, prefer `:where()`/class selectors, avoid `!important`.
2. **Tokens** — centralize design tokens with custom properties; no hardcoded magic values.
3. **Logical properties** — prefer `margin-inline`, `padding-block`, `inset-inline` over physical left/right.
4. **Layout primitives** — `gap`, `aspect-ratio`, Grid/Flex, container queries, `subgrid`, `inset` shorthand.
5. **Animation** — transform/opacity-based motion, respect `prefers-reduced-motion`, no JS-driven style hacks when native CSS works.
6. **Accessibility** — preserve `:focus-visible`, keyboard semantics; never trade a11y for visual polish.
7. **Readability** — limit deep selector chains, avoid unnecessary nesting, keep component styles local.

## Output Format

1. **Recommendation** — one concise modern replacement
2. **Why** — maintainability/perf/a11y in 1–2 lines
3. **Compatibility** — mode + tier + verification note
4. **Fallback** — required for B/C, optional for A
5. **Code patch** — copy-paste ready

## References

- `references/index.md` — entrypoint, rule map, and quick search commands
- `references/profiles/` — `stable.md` (A), `progressive.md` (B), `experimental.md` (C)
- `references/css-techniques-guide.md` — full catalog and examples
- `references/rules/` — per-technique rule files with tier, `bcd_id`, `mdn_url`, and caveats

## Anti-Patterns

- Recommending B/C features without a baseline fallback
- Using snapshot `%` support values as sole evidence
- Offering multiple competing solutions when one clear path suffices
- Introducing `!important` or deep specificity chains without necessity
- Returning style advice without concrete patch-level code
- Outputting framework-specific syntax when user asked for plain CSS
