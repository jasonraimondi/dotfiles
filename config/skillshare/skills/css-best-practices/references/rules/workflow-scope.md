---
title: @scope for Scoped Styles
impact: MEDIUM
browser: 84%
bcd_id: css.at-rules.scope
tags: workflow, scope, bem, css-modules, encapsulation
---

## @scope for Scoped Styles

Use `@scope` instead of BEM naming conventions or CSS Modules.

**Old (BEM):**

```css
.card__title { font-size: 1.25rem; }
.card__body { color: #444; }
/* or CSS Modules / styled-components */
```

**Modern (native scope):**

```css
@scope (.card) to (.card-footer) {
  .title { font-size: 1.25rem; }
  .body { color: #444; }
}
```

Styles only apply within `.card` and stop at `.card-footer`. No naming conventions needed.
