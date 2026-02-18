---
title: Grid Centering Without Transform Hack
impact: CRITICAL
browser: 97%
bcd_id: css.properties.place-items.grid_context
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/place-items
tags: layout, centering, grid, place-items
---

## Grid Centering Without Transform Hack

Use `display: grid; place-items: center` instead of the absolute + transform centering hack.

**Old (transform hack):**

```css
.child {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}
```

**Modern:**

```css
.parent {
  display: grid;
  place-items: center;
}
/* child needs nothing */
```
