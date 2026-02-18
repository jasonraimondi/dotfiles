---
title: Drop Caps Without Float Hacks
impact: LOW
browser: 91%
bcd_id: css.properties.initial-letter
tags: typography, initial-letter, drop-cap
---

## Drop Caps Without Float Hacks

Use `initial-letter` instead of float + font-size hacks.

**Old (float hack):**

```css
.article > p:first-of-type::first-letter {
  float: left;
  font-size: 3em;
  line-height: 1;
  margin-right: 0.1em;
}
```

**Modern:**

```css
.article > p:first-of-type {
  initial-letter: 3;
}
```
