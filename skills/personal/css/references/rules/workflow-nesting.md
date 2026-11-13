---
title: Native CSS Nesting
impact: HIGH
browser: 91%
tier: A
bcd_id: css.selectors.nesting
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Selectors/Nesting_selector
tags: workflow, nesting, sass, preprocessor
---

## Native CSS Nesting

Use native CSS nesting instead of Sass/Less.

**Old (requires Sass compiler):**

```scss
// requires Sass compiler
.nav {
  & a { color: #888; }
  &:hover { background: #f5f5f5; }
}
```

**Modern (plain .css, no build):**

```css
.nav {
  & a { color: #888; }
  &:hover { background: #f5f5f5; }

  @media (width < 768px) {
    flex-direction: column;
  }
}
```

Works in plain `.css` files. No preprocessor needed.
