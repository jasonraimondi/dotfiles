---
title: Native Color Mixing
impact: MEDIUM
browser: 89%
tier: B
bcd_id: css.types.color.color-mix
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Values/color_value/color-mix
tags: color, color-mix, blend, preprocessor
---

## Native Color Mixing

Use `color-mix()` instead of Sass `mix()` function.

**Old (Sass):**

```scss
$blend: mix($blue, $pink, 60%);
```

**Modern (native CSS):**

```css
.blended {
  background: color-mix(in oklch, #3b82f6, #ec4899);
}

/* With custom ratio */
.mostly-blue {
  background: color-mix(in oklch, #3b82f6 70%, #ec4899);
}
```

Always use `in oklch` for perceptually smooth blending.

**Fallback (progressive enhancement):**

```css
/* Baseline: precomputed token */
:root {
  --brand-blend: #7b6fd2;
}

.blended {
  background: var(--brand-blend);
}

/* Upgrade when color-mix() is supported */
@supports (color: color-mix(in oklch, red, white)) {
  .blended {
    background: color-mix(in oklch, #3b82f6, #ec4899);
  }
}
```
