---
title: Auto-Growing Textarea Without JavaScript
impact: HIGH
browser: 73%
bcd_id: css.properties.field-sizing.content
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/field-sizing
tags: layout, textarea, field-sizing, forms
---

## Auto-Growing Textarea Without JavaScript

Use `field-sizing: content` instead of JS measuring scrollHeight on every keystroke.

**Old (JS resize):**

```js
el.addEventListener("input", () => {
  el.style.height = "auto";
  el.style.height = el.scrollHeight + "px";
});
```

**Modern:**

```css
textarea {
  field-sizing: content;
  min-height: 3lh;
}
```

**Fallback (progressive enhancement):**

```css
/* Baseline fallback */
textarea {
  min-height: 3lh;
  resize: vertical;
}

/* Upgrade when field-sizing is supported */
@supports (field-sizing: content) {
  textarea {
    field-sizing: content;
    resize: none;
  }
}
```
