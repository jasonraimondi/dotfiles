---
title: Accent Color for Form Controls
impact: MEDIUM
browser: 95%
bcd_id: css.properties.accent-color
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/accent-color
tags: color, forms, accent-color, checkbox, radio
---

## Accent Color for Form Controls

Use `accent-color` instead of `appearance: none` + rebuilding form controls from scratch.

**Old (rebuild from scratch):**

```css
input[type="checkbox"] {
  appearance: none;
  width: 16px;
  height: 16px;
  border: 2px solid #ccc;
  border-radius: 3px;
  /* 20+ more lines for checked state, focus, etc. */
}
```

**Modern (tint native controls):**

```css
input[type="checkbox"],
input[type="radio"] {
  accent-color: #7c3aed;
}
```
