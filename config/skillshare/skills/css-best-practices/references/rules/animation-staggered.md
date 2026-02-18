---
title: Staggered Animations with sibling-index()
impact: MEDIUM
browser: 60%
bcd_id: css.types.sibling-index
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Values/sibling-index
tags: animation, stagger, sibling-index, nth-child
---

## Staggered Animations with sibling-index()

Use `sibling-index()` instead of hardcoded nth-child delay values.

**Old (hardcoded nth-child):**

```css
.item:nth-child(1) { animation-delay: 0.1s; }
.item:nth-child(2) { animation-delay: 0.2s; }
.item:nth-child(3) { animation-delay: 0.3s; }
/* ...repeat for every child */
```

**Modern:**

```css
.item {
  animation-delay: calc(sibling-index() * 0.1s);
}
```

**Fallback (progressive enhancement):**

```css
/* Baseline fallback using a custom property */
.item {
  animation-delay: calc(var(--stagger-index, 0) * 0.1s);
}

/* Optional utility: set --stagger-index inline or via JS */
```

Use `sibling-index()` when available; otherwise set `--stagger-index` manually.
