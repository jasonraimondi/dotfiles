---
title: :is() for Selector Grouping
impact: MEDIUM
browser: 96%
tier: A
bcd_id: css.selectors.is
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Selectors/:is
tags: selector, is, grouping, shorthand
---

## :is() for Selector Grouping

Use `:is()` to group selectors instead of repeating parent selectors.

**Old (repeated parent):**

```css
.card h1,
.card h2,
.card h3 {
  margin-bottom: 0.5em;
}
```

**Modern:**

```css
.card :is(h1, h2, h3) {
  margin-bottom: 0.5em;
}
```

Note: `:is()` takes the highest specificity of its arguments. Use `:where()` for zero specificity.
