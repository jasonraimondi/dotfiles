---
title: Page Transitions Without a Framework
impact: HIGH
browser: 89%
tier: B
bcd_id: css.properties.view-transition-name
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/view-transition-name
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

### Notes & Caveats
- `view-transition-name` must be unique across the entire document during the transition.
- Use distinct names for elements you want to animate separately (e.g., `hero-1`, `hero-2`).

**Fallback (progressive enhancement):**

```js
// Baseline: update immediately when View Transitions API is unavailable
if (!document.startViewTransition) {
  updateDOM();
} else {
  document.startViewTransition(() => updateDOM());
}
```

```css
/* Optional enhancement styles only when supported */
@supports (view-transition-name: hero) {
  .hero { view-transition-name: hero; }

  ::view-transition-old(hero) { animation: fadeOut 0.3s ease; }
  ::view-transition-new(hero) { animation: fadeIn 0.3s ease; }
}
```
