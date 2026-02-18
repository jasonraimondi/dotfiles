---
title: Custom Select with appearance: base-select
impact: HIGH
browser: 65%
bcd_id: css.properties.appearance.base-select
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/appearance
tags: interactive, select, dropdown, forms, customization
---

## Custom Select with appearance: base-select

Use `appearance: base-select` instead of Select2 or Choices.js libraries.

**Old (library rebuild):**

```js
new Choices(document.querySelector("select"), {
  searchEnabled: true,
  itemSelectText: "",
});
// Rebuilds entire DOM, adds 30KB+
```

**Modern:**

```css
select {
  appearance: base-select;
}

select::picker(select) {
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}
```

**Fallback (progressive enhancement):**

```css
/* Baseline native select styling */
select {
  appearance: auto;
}

/* Upgrade when base-select is supported */
@supports (appearance: base-select) {
  select {
    appearance: base-select;
  }

  select::picker(select) {
    background: white;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  }
}
```
