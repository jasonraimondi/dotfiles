---
name: css-best-practices
description: Browser-aware modern CSS patterns with progressive-enhancement fallbacks. Activate only for concrete styling work in CSS/Tailwind/Svelte (layout, spacing, typography, color/theming, animation, responsive/container queries, selectors/specificity, or replacing legacy CSS/JS style hacks). Do not activate for non-styling app logic or design critique without code changes.
---

# CSS Best Practices

## Overview

Comprehensive modern CSS guide with 62 rules across 7 categories, sourced from modern-css.com. Each rule shows the outdated approach and its modern CSS replacement. Rules are prioritized by browser support and impact.

## When to Apply

Reference these guidelines when:
- Writing new CSS, Tailwind, or Svelte component styles
- Reviewing CSS for outdated patterns or JS workarounds
- Replacing preprocessor features (Sass/Less) with native CSS
- Implementing layouts, animations, or responsive design
- Optimizing rendering performance
- Implementing dark mode, theming, or color systems

## MDN Verification Workflow (Inspired by css-mcp)

When recommending modern CSS features, verify docs + support first:

1. Fetch docs for each feature before recommending (`grid`, `:has`, `@container`, `popover`, etc.)
2. Verify Browser Compat Data (BCD) for features that may need fallbacks
3. Apply support tiers below before replacing existing production patterns
4. Add progressive-enhancement fallback snippets for Tier B/C features

Each rule file in `references/rules/` includes:
- `bcd_id` — canonical compatibility lookup key
- `mdn_url` — direct MDN documentation link for fast verification
- `browser` — support snapshot estimate (not a live source of truth)

⚠️ `browser` percentages are point-in-time estimates and can drift. Always verify current support via `bcd_id` lookup and/or the `mdn_url` page before making production recommendations.

If MCP tools are unavailable, verify using MDN docs and MDN browser compatibility tables manually.

## Support Tiers & Recommendation Policy

| Tier | Browser Support | Recommendation |
|------|-----------------|----------------|
| A | >= 90% | Safe default in most production code |
| B | 80-89% | Use with fallback (`@supports`, graceful degradation) |
| C | < 80% | Progressive enhancement only; keep baseline fallback |

## CSS Audit Workflow (Summary-First)

When auditing CSS quality/performance, use a lightweight-first approach:

1. Start with high-level metrics (SLOC, total rules, selector complexity, unique colors/font sizes)
2. Flag hotspots (max specificity, deeply nested selectors, duplicated patterns)
3. Deep-dive only into flagged areas to avoid noisy reviews

This mirrors css-mcp's summary-first analysis pattern to keep guidance fast and focused.

## Priority-Ordered Guidelines

| Priority | Category | Impact |
|----------|----------|--------|
| 1 | Layout & Spacing | CRITICAL — most common patterns |
| 2 | Animation & Transitions | HIGH — eliminates JS dependencies |
| 3 | Color & Theming | HIGH — removes preprocessor needs |
| 4 | Typography | MEDIUM — improves text rendering |
| 5 | Selectors & Specificity | MEDIUM — cleaner selector patterns |
| 6 | Workflow & Architecture | MEDIUM — native CSS features |
| 7 | Interactive UI | HIGH — replaces JS-heavy components |

## Quick Reference

### Critical Layout Patterns (Apply First)

- Use `gap` instead of margin hacks for spacing
- Use `aspect-ratio` instead of padding-top trick
- Use `inset: 0` instead of top/right/bottom/left
- Use `object-fit: cover` instead of background-image hacks
- Use logical properties (`margin-inline-start`) instead of left/right
- Use `position: sticky` instead of JS scroll listeners
- Use container queries (`@container`) instead of media queries
- Use `grid-template-areas` for semantic grid layouts
- Use `subgrid` instead of duplicating parent track definitions
- Use `scrollbar-gutter: stable` to prevent layout shift
- Use `field-sizing: content` for auto-growing textareas
- Use `content-visibility: auto` for lazy rendering

### Animation Patterns (Eliminate JS)

- Use `interpolate-size: allow-keywords` for height:auto transitions
- Use `transition-behavior: allow-discrete` for display:none animations
- Use `@starting-style` for entry animations
- Use `animation-timeline: view()` for scroll-linked animations
- Use separate `translate`/`rotate`/`scale` properties
- Use `view-transition-name` for page transitions

### Color & Theming

- Use `oklch()` for perceptually uniform colors
- Use `color-mix()` instead of Sass mix()
- Use `light-dark()` for dark mode without duplication
- Use `accent-color` instead of rebuilding form controls
- Use relative color syntax for color variants
- Use `color-scheme: light dark` for automatic dark defaults

### Typography

- Use `text-wrap: balance` for balanced headlines
- Use `clamp()` for fluid typography
- Use `line-clamp` for multiline truncation
- Use `font-display: swap` to avoid invisible text
- Use variable fonts instead of multiple font files

### Selectors & Specificity

- Use `:has()` instead of JS parent selection
- Use `:focus-visible` instead of `:focus`
- Use `:where()` for zero-specificity resets
- Use `:is()` to group selectors
- Use `:user-invalid` for form validation styles
- Use `@layer` instead of `!important` wars

### Workflow & Architecture

- Use native CSS nesting instead of Sass
- Use `@scope` instead of BEM naming
- Use CSS custom properties instead of Sass variables
- Use `@property` for typed custom properties
- Use native `@function` instead of Sass functions
- Use typed `attr(... type())` for attribute-driven styles (experimental)
- Use range style queries for threshold-based styling (experimental)

### Interactive UI (Replace JS Libraries)

- Use `<dialog>` instead of modal libraries
- Use `popover` attribute instead of JS dropdowns
- Use CSS anchor positioning instead of Popper.js
- Use `scroll-snap-type` instead of carousel libraries
- Use `::scroll-button()` / `::scroll-marker` for carousel nav
- Use `appearance: base-select` for custom selects
- Use `commandfor` / `command` for dialog triggers

## References

Full documentation with code examples:

- `references/modern-css-guide.md` — Complete guide with all patterns
- `references/rules/` — Individual rule files by category

To look up a specific pattern:
```
rg -l "container" references/rules
rg -l "oklch" references/rules
```

## Rule Categories in `references/rules/`

- `layout-*` — Layout and spacing patterns
- `animation-*` — Animation and transition patterns
- `color-*` — Color and theming
- `typography-*` — Typography and text
- `selector-*` — Selectors and specificity
- `workflow-*` — CSS architecture and preprocessing
- `interactive-*` — Interactive UI components
