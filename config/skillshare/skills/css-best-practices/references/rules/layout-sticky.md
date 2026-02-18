---
title: Sticky Headers Without JS Scroll Listeners
impact: HIGH
browser: 97%
bcd_id: css.properties.position.sticky
tags: layout, sticky, positioning, scroll
---

## Sticky Headers Without JS Scroll Listeners

Use `position: sticky` instead of JavaScript scroll listeners with `getBoundingClientRect`.

**Old (JS scroll listener):**

```js
window.addEventListener("scroll", () => {
  const rect = header.getBoundingClientRect();
  header.classList.toggle("stuck", rect.top <= 0);
});
```

**Modern:**

```css
.header {
  position: sticky;
  top: 0;
  z-index: 10;
}
```
