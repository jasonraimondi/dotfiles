---
title: OKLCH for Perceptually Uniform Colors
impact: HIGH
browser: 90%
bcd_id: css.types.color.oklch
tags: color, oklch, color-space, palette
---

## OKLCH for Perceptually Uniform Colors

Use `oklch()` instead of hex/rgb for predictable lightness and saturation adjustments.

**Old (hex guessing):**

```css
:root {
  --blue-500: #3b82f6;
  --blue-600: #2563eb; /* guessed darker */
  --blue-400: #60a5fa; /* guessed lighter */
}
```

**Modern (OKLCH — change lightness predictably):**

```css
:root {
  --blue-500: oklch(0.55 0.2 264);
  --blue-600: oklch(0.45 0.2 264); /* just lower L */
  --blue-400: oklch(0.65 0.2 264); /* just higher L */
}
```

OKLCH components: `oklch(lightness chroma hue)` — L: 0-1, C: 0-0.4, H: 0-360.
