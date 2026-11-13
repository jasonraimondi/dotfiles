# CSS Author Preferences

Opinionated rules layered on top of `SKILL.md`. When this file conflicts with a rule in `../references/rules/`, prefer the rule file (it carries `tier` + `bcd_id`); apply this file's framing for *which* idiomatic option to reach for first.

## Quick Reference

| Need              | Reach for                                           | Rule file                                                                |
| ----------------- | --------------------------------------------------- | ------------------------------------------------------------------------ |
| Variants          | Override the variable downstream props read        | `selector-layer.md`, `workflow-custom-properties.md`                     |
| Specificity fight | `@layer` ordering, not selector chains             | `selector-layer.md`, `selector-where.md`                                 |
| Responsive        | `clamp()` / `minmax()` / `auto-fit` before queries | `layout-gap-spacing.md`, `typography-fluid.md`                           |
| Scope             | SFC styles, CSS Modules, or `@scope`               | `workflow-scope.md`                                                      |
| Component-local   | `@property` with `inherits: false`                 | `workflow-custom-properties.md`                                          |
| Color variants    | `color-mix()` / relative color from a base token   | `color-oklch.md`                                                         |

---

## Tier 1 — Architectural (non-negotiable)

Break these and the codebase rots.

1. **Render correctly in isolation.** A component dropped on a blank page must look identical to its in-situ form. Styles travel with the component.
2. **Reference design tokens via CSS custom properties.** Every color, font family, font size, shadow, spacing value, radius, and z-index is a `var(--*)` lookup. The token registry is the single source of truth.
3. **Express variants by overriding the variable downstream properties read from.** `button[data-variant="danger"]` sets `--button-bg`; borders, shadows, and hover states stay in sync because they all derive from it. A clean variant block is one or two declarations.
4. **Resolve specificity with `@layer`, not selector chains.** Place a rule in the layer that should win.
5. **Reach for intrinsic layout first.** `grid`, `flex-wrap`, `auto-fit`, `auto-fill`, `minmax()`, `clamp()`. Media queries cover what genuinely needs a breakpoint.
6. **Scope styles to their component.** SFC styles, CSS Modules, or `@scope`. Global CSS holds resets, base typography, and tokens — nothing else.

## Tier 2 — Strong defaults

Distinguish good CSS from passable CSS.

7. **Style raw HTML in the base layer.** A page of unclassed HTML (forms, tables, headings, lists) should already look on-brand. Components inherit from base; they do not recreate it.
8. **Define tokens once at `:root`; override at the component level when needed.** Lean on the cascade.
9. **Derive related values from a base token** with `color-mix()` or relative color syntax. No parallel hex variants.
10. **Fluid typography with `clamp()`** keyed off viewport or container size. One declaration covers the full range.
11. **Nest queries inside the selector.** One selector owns all its responsive behavior in one place.
12. **Organize globals into ordered `@layer`s.** Suggested: `reset, base, tokens, components, utilities, overrides` — declared at the top of the entry stylesheet.
13. **Use `@property` with `inherits: false` for layout primitives** like `--gap`, `--padding`, `--columns` so they stay local to their component instance.
14. **Extract reusable primitives.** Generic patterns (table, heading, section, card) live as components or classes any page can use. A name like `.admin-page-table` is a smell — extract it.
15. **Compose components from tokens** so a token change propagates site-wide automatically.

## Tier 3 — Refinements

Sharpen the edges once Tiers 1–2 hold.

16. **Container queries when component size matters; media queries when the viewport is the constraint.**
17. **Use `@scope` with donut scoping** for styles that should stay within a boundary and stop at any nested instance (e.g. card-in-card).
18. **Inline-style variable overrides for one-offs:** `style="--accent: blue"`. Beats inventing a new selector.
19. **Keep selectors top-level scoped.** When a child's internals matter, expose a variable or prop — don't reach in.
20. **Use scoped styles or `data-*` attributes for variants.** Style local elements directly; differentiate states with `data-*`.
21. **Let the linter be the bad guy.** Configure Stylelint or Biome to enforce token usage so colors, font sizes, shadows, and spacing must be `var(--*)`.
22. **New tokens go in the central tokens file.** Registry stays the single source of truth.

---

## Pre-flight checklist

Run before committing any CSS rule:

- [ ] Could this live on a raw element selector in the base layer?
- [ ] Is every color, size, shadow, and space a `var(--*)` token?
- [ ] Could `clamp()`, `minmax()`, or `auto-fit` handle the responsiveness?
- [ ] For variants — am I overriding a variable that other properties already read?
- [ ] For overrides — could `@layer` ordering handle this instead?
- [ ] Does this style stay inside its component, both in what it affects and what it reads from?

If any answer is "no" without a stated reason, revise before committing.
