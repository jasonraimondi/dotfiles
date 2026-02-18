---
title: @scope for Scoped Styles
impact: MEDIUM
browser: 84%
bcd_id: css.at-rules.scope
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/At-rules/@scope
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

**Fallback (progressive enhancement):**

```css
/* Baseline: prefixed selectors / BEM-style scoping */
.card .title { font-size: 1.25rem; }
.card .body { color: #444; }
```

```css
/* Enhancement: native scope boundaries */
@scope (.card) to (.card-footer) {
  .title { font-size: 1.25rem; }
  .body { color: #444; }
}
```
