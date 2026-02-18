---
title: Balanced Text Wrap
impact: HIGH
browser: 87%
bcd_id: css.properties.text-wrap.balance
tags: typography, text-wrap, balance, headlines
---

## Balanced Text Wrap

Use `text-wrap: balance` for headlines and `text-wrap: pretty` for paragraphs.

**Old (manual breaks or JS):**

```html
<h1>Some Headline That<br>Wraps Oddly</h1>
<!-- or Balance-Text.js library -->
```

**Modern:**

```css
h1, h2, h3 {
  text-wrap: balance;
}

p {
  text-wrap: pretty; /* prevents orphans */
}
```
