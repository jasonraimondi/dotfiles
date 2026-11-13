---
title: Font Display Swap
impact: MEDIUM
browser: 97%
tier: A
bcd_id: css.at-rules.font-face.font-display
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/At-rules/@font-face/font-display
tags: typography, font-display, foit, performance
---

## Font Display Swap

Use `font-display: swap` to show fallback text immediately during font load.

**Old (invisible text flash — FOIT):**

```css
@font-face {
  font-family: "Custom";
  src: url("custom.woff2");
  /* no font-display = invisible text until loaded */
}
```

**Modern:**

```css
@font-face {
  font-family: "Custom";
  src: url("custom.woff2");
  font-display: swap;
}
```
