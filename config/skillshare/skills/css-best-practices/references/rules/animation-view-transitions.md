---
title: Page Transitions Without a Framework
impact: HIGH
browser: 89%
bcd_id: css.properties.view-transition-name
tags: animation, view-transitions, page-transition, spa
---

## Page Transitions Without a Framework

Use the View Transitions API instead of Barba.js or framework transition libraries.

**Old (Barba.js):**

```js
Barba.init({
  transitions: [{ leave: () => fadeOut(), enter: () => fadeIn() }],
});
```

**Modern:**

```js
document.startViewTransition(() => updateDOM());
```

```css
.hero {
  view-transition-name: hero;
}

::view-transition-old(hero) {
  animation: fadeOut 0.3s ease;
}

::view-transition-new(hero) {
  animation: fadeIn 0.3s ease;
}
```
