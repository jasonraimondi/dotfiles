---
title: Backdrop Filter (Frosted Glass)
impact: MEDIUM
browser: 95%
bcd_id: css.properties.backdrop-filter
tags: color, backdrop-filter, blur, frosted-glass
---

## Backdrop Filter (Frosted Glass)

Use `backdrop-filter: blur()` instead of pseudo-element background image hacks.

**Old (pseudo-element hack):**

```css
.glass::before {
  content: "";
  position: absolute;
  inset: 0;
  background: inherit;
  filter: blur(12px);
  z-index: -1;
}
```

**Modern:**

```css
.glass {
  backdrop-filter: blur(12px);
  background: rgba(255, 255, 255, 0.1);
}
```
