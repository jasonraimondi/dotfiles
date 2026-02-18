---
title: Inset Shorthand
impact: HIGH
browser: 96%
bcd_id: css.properties.inset
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/inset
tags: layout, positioning, inset, shorthand
---

## Inset Shorthand

Use `inset` instead of separate `top`, `right`, `bottom`, `left` declarations.

**Old:**

```css
.overlay {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
}
```

**Modern:**

```css
.overlay {
  position: absolute;
  inset: 0;
}
```

Also supports shorthand like `inset: 10px 20px` (vertical horizontal).
