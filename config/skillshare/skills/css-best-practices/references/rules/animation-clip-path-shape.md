---
title: Responsive Clip Paths with shape()
impact: LOW
browser: 55%
bcd_id: css.types.basic-shape.shape
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Values/basic-shape/shape
tags: animation, clip-path, shape, responsive
---

## Responsive Clip Paths with shape()

Use CSS `shape()` function instead of SVG `path()` for responsive clip paths.

**Old (SVG path — doesn't scale):**

```css
.blob {
  clip-path: path("M150,0 C250,0 300,100 250,200...");
  /* Fixed pixel coordinates, not responsive */
}
```

**Modern:**

```css
.blob {
  clip-path: shape(
    from 0% 50%,
    curve to 100% 50% via 50% 0%,
    curve to 0% 50% via 50% 100%
  );
}
```

Uses percentages and relative units — scales with the element.

**Fallback (progressive enhancement):**

```css
.blob {
  clip-path: ellipse(50% 50% at 50% 50%);
}

@supports (clip-path: shape(from 0% 50%, curve to 100% 50% via 50% 0%, curve to 0% 50% via 50% 100%)) {
  .blob {
    clip-path: shape(
      from 0% 50%,
      curve to 100% 50% via 50% 0%,
      curve to 0% 50% via 50% 100%
    );
  }
}
```
