# CSS Rules Index (Fast Entry)

Use this file first to avoid loading unnecessary rule files.

## How to Use

1. Pick a compatibility mode:
   - Baseline → `profiles/stable.md`
   - Progressive → `profiles/progressive.md`
   - Experimental → `profiles/experimental.md`
2. Then load only the few matching rule files in `rules/`.

## High-Impact Starter Rules (Idiomatic CSS)

Start with these before lower-impact optimizations:

- **Cascade / specificity:** `selector-layer.md`, `selector-where.md`, `selector-focus-visible.md`
- **Layout / spacing:** `layout-gap-spacing.md`, `layout-aspect-ratio.md`, `layout-container-queries.md`, `layout-logical-properties.md`
- **Theme / color:** `workflow-custom-properties.md`, `color-scheme.md`, `color-oklch.md`
- **Typography:** `typography-fluid.md`, `typography-line-clamp.md`, `typography-variable-fonts.md`
- **Motion / interaction:** `animation-independent-transforms.md`, `interactive-dialog.md`, `interactive-scroll-snap.md`

## Rule Prefix Map

- `layout-*` → spacing, sizing, placement, responsiveness
- `animation-*` → motion/transitions/timelines
- `color-*` → color spaces, theme switching, appearance
- `typography-*` → font rendering, wrapping, truncation, scale
- `selector-*` → specificity, targeting, state selectors
- `workflow-*` → architecture features (`@scope`, nesting, custom props)
- `interactive-*` → native UI patterns (`dialog`, `popover`, snap)

## Quick Search

```bash
rg -l "^tier: A$" references/rules
rg -l "^tier: B$" references/rules
rg -l "^tier: C$" references/rules
rg -l "@layer|:where|:has|focus-visible" references/rules
rg -l "container|subgrid|gap|logical|aspect-ratio" references/rules
rg -l "oklch|color-mix|light-dark|color-scheme" references/rules
rg -l "starting-style|timeline|transition-behavior|interpolate-size" references/rules
```
