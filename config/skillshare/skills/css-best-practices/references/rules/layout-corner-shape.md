---
title: Corner Shapes Beyond Border Radius
impact: LOW
browser: 50%
bcd_id: css.properties.corner-shape
tags: layout, corner-shape, squircle, border-radius
---

## Corner Shapes Beyond Border Radius

Use `corner-shape` for squircle and other corner shapes instead of complex `clip-path: polygon()`.

**Old (clip-path with coordinates):**

```css
.card {
  clip-path: polygon(/* 20+ coordinate points for squircle */);
}
```

**Modern:**

```css
.card {
  corner-shape: squircle;
  border-radius: 20px;
}
```

**Fallback (progressive enhancement):**

```css
.card {
  border-radius: 20px;
}

@supports (corner-shape: squircle) {
  .card {
    corner-shape: squircle;
    border-radius: 20px;
  }
}
```

Note: Limited browser support as of 2026.
