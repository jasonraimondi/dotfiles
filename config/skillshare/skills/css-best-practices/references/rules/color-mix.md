---
title: Native Color Mixing
impact: MEDIUM
browser: 89%
bcd_id: css.types.color.color-mix
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
