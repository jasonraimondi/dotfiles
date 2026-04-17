---
title: Multiline Text Truncation
impact: MEDIUM
browser: 95%
tier: A
bcd_id: css.properties.line-clamp
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/line-clamp
tags: typography, line-clamp, truncation, ellipsis
---

## Multiline Text Truncation

Use `line-clamp` (or `-webkit-line-clamp`) instead of JS character counting.

**Old (JS truncation):**

```js
const maxChars = 150;
el.textContent = text.slice(0, maxChars) + "...";
```

**Modern:**

```css
.excerpt {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
```
