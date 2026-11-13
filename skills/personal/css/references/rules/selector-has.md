---
title: :has() Parent Selector
impact: CRITICAL
browser: 94%
tier: A
bcd_id: css.selectors.has
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Selectors/:has
tags: selector, has, parent, conditional
---

## :has() Parent Selector

Use `:has()` to select elements based on their descendants, instead of JS `closest()`.

**Old (JavaScript):**

```js
el.closest(".parent").classList.add("has-image");
```

**Modern:**

```css
/* Style parent based on child */
.card:has(img) {
  grid-template-rows: auto 1fr;
}

/* Disable submit when form is invalid */
.form:has(:invalid) .submit {
  opacity: 0.5;
  pointer-events: none;
}

/* Style sibling based on state */
input:has(+ .error:not(:empty)) {
  border-color: red;
}
```
