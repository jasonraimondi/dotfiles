---
name: frontend-css-best-practices
description: Produce idiomatic, browser-aware modern CSS with progressive-enhancement fallbacks for CSS, Tailwind, and Svelte styling tasks. Use for layout, spacing, typography, color/theming, animation, responsive/container-query work, selector/specificity cleanup, and interactive UI styling. Do not use for non-styling business logic or design critique without code edits.
---

# CSS Best Practices

Use this skill to replace outdated styling patterns with idiomatic CSS that is maintainable, accessible, and performance-aware.

## Defaults (Important)

- **Default output:** vanilla CSS (only output Tailwind/Svelte when user asks).
- **Default compatibility mode:** **Baseline** (Tier A features by default).
- **Default recommendation count:** one primary solution, not multiple competing options.
- **Use rule metadata deterministically:** select features by each rule’s `tier` field first, then verify with `mdn_url` + `bcd_id`.

## Compatibility Modes

Choose mode before proposing implementation:

| Mode | Allowed tiers | When to use |
|---|---|---|
| **Baseline** (default) | A only (`>=90%`) | Production-safe default, unknown browser matrix |
| **Progressive** | A + B (`80–89%`) | User accepts fallbacks and progressive enhancement |
| **Experimental** | A + B + C (`<80%`) | User explicitly asks for cutting-edge CSS |

For B/C features, keep a robust baseline and layer enhancements with `@supports`.

Rule frontmatter includes explicit `tier: A|B|C` values. Treat `browser:` as informational snapshot only.

## Idiomatic CSS Contract (Must Follow)

1. **Design the cascade intentionally**
   - Use `@layer` ordering where applicable.
   - Prefer low-specificity selectors (`:where()`, class-based selectors).
   - Avoid `!important` unless constraint is explicit.

2. **Use tokenized styles**
   - Centralize design tokens with custom properties.
   - Avoid hardcoded repeated magic values for spacing/color/typography.

3. **Prefer logical and flow-relative properties**
   - Use `margin-inline`, `padding-block`, `inset-inline`, etc., over physical left/right when possible.

4. **Prefer native layout primitives**
   - `gap`, `aspect-ratio`, Grid/Flex, container queries, `subgrid` (when supported), `inset` shorthand.

5. **Animation and performance rules**
   - Prefer transform/opacity-based motion where possible.
   - Respect `prefers-reduced-motion`.
   - Avoid JS-driven style hacks when native CSS can replace them.

6. **Accessibility is non-negotiable**
   - Preserve visible focus (`:focus-visible`).
   - Preserve keyboard interaction semantics.
   - Do not trade a11y for visual polish.

7. **Keep CSS readable and composable**
   - Limit deep selector chains.
   - Avoid unnecessary nesting.
   - Keep component styles local and predictable.

## Workflow (Use This Order)

1. **Identify styling objective + constraints**
   - Clarify desired change (layout/motion/theme/selectors/etc.)
   - Clarify constraints (browser support, accessibility, framework)

2. **Select compatibility mode**
   - Baseline by default unless user requests more aggressive modernization

3. **Load only required references**
   - Read `references/index.md`
   - Read one profile file in `references/profiles/` matching mode
   - Read only relevant rule files from `references/rules/`

4. **Verify support and caveats**
   - Confirm selected rule `tier` matches chosen mode
   - Use each rule’s `mdn_url` and `bcd_id`
   - Treat frontmatter `browser` values as snapshots only

5. **Implement one primary recommendation**
   - Provide patch-level CSS/Tailwind/Svelte change
   - Include fallback for B/C features

6. **Run final quality checks**
   - No a11y regression
   - No unnecessary specificity escalation
   - No avoidable JS workaround retained
   - Motion honors reduced-motion preferences

## Output Format (Use Exactly)

1. **Recommendation** — one concise modern replacement
2. **Why** — maintainability/perf/a11y in 1–2 lines
3. **Compatibility** — mode + tier + verification note
4. **Fallback** — required for B/C (optional for A)
5. **Code patch** — final implementation (copy-paste ready)

## Rule Loading Aids

Use targeted lookup before reading files broadly:

```bash
rg -l "container|@container|subgrid|gap|aspect-ratio" references/rules
rg -l "focus-visible|:has|:where|:is|@layer" references/rules
rg -l "oklch|color-mix|light-dark|color-scheme" references/rules
rg -l "@starting-style|timeline|transition-behavior|interpolate-size" references/rules
```

## References

- `references/index.md` — fast entrypoint + rule map
- `references/profiles/stable.md` — Tier A starter set
- `references/profiles/progressive.md` — Tier B features requiring fallbacks
- `references/profiles/experimental.md` — Tier C progressive-only features
- `references/css-techniques-guide.md` — full catalog and examples
- `references/rules/` — per-technique rule files with metadata and caveats

## Anti-Patterns to Avoid

- Recommending B/C features without a baseline fallback
- Shipping recommendations using snapshot `%` support values alone
- Offering multiple default solutions when one clear path is enough
- Introducing `!important` or deep specificity chains without necessity
- Returning style advice without concrete patch-level code
- Outputting framework-specific syntax when user asked for plain CSS
