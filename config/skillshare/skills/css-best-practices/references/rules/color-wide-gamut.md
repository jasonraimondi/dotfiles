---
title: Wide Gamut Colors (Display-P3)
impact: MEDIUM
browser: 90%
bcd_id: css.types.color.color.colorSpace_parameter_accepts_display-p3-linear_value
tags: color, display-p3, wide-gamut, hdr
---

## Wide Gamut Colors (Display-P3)

Use Display-P3 or OKLCH for vivid colors beyond the sRGB gamut.

**Old (sRGB only):**

```css
.hero {
  color: rgb(200, 80, 50); /* washed out on P3 displays */
}
```

**Modern (wide gamut):**

```css
.hero {
  color: oklch(0.7 0.25 29);
}

/* Or explicit Display-P3 */
.vivid {
  color: color(display-p3 1 0.2 0.1);
}
```
