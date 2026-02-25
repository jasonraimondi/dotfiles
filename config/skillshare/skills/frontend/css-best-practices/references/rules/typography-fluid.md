---
title: Fluid Typography with clamp()
impact: HIGH
browser: 96%
tier: A
bcd_id: css.types.clamp
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Values/clamp
tags: typography, fluid, clamp, responsive
---

## Fluid Typography with clamp()

Use `clamp()` for smooth font scaling instead of multiple media query breakpoints.

**Old (breakpoint steps):**

```css
h1 { font-size: 2rem; }
@media (min-width: 768px) { h1 { font-size: 2.5rem; } }
@media (min-width: 1200px) { h1 { font-size: 3.5rem; } }
```

**Modern (smooth scaling):**

```css
h1 {
  font-size: clamp(2rem, 1rem + 2.5vw, 3.5rem);
}
```

Formula: `clamp(min, preferred, max)` where preferred uses viewport units.
