---
title: :where() for Zero-Specificity Resets
impact: MEDIUM
browser: 96%
bcd_id: css.selectors.where
tags: selector, where, specificity, resets
---

## :where() for Zero-Specificity Resets

Use `:where()` for zero-specificity selectors that are easy to override.

**Old (verbose resets with specificity):**

```css
.reset ul,
.reset ol {
  list-style: none;
  padding: 0;
}
```

**Modern (zero specificity):**

```css
:where(ul, ol) {
  list-style: none;
  padding: 0;
  margin: 0;
}

:where(h1, h2, h3, h4) {
  margin: 0;
}
```

`:where()` has zero specificity — any later rule overrides it without fighting.
