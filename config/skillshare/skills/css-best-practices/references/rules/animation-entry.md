---
title: Entry Animations with @starting-style
impact: HIGH
browser: 85%
bcd_id: css.at-rules.starting-style
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/At-rules/@starting-style
tags: animation, transition, entry, starting-style
---

## Entry Animations with @starting-style

Use `@starting-style` for entrance animations instead of JS `requestAnimationFrame` class toggling.

**Old (rAF class toggle):**

```js
requestAnimationFrame(() => {
  el.classList.add("visible");
});
```

**Modern:**

```css
.card {
  opacity: 1;
  transform: translateY(0);
  transition: opacity 0.3s, transform 0.3s;

  @starting-style {
    opacity: 0;
    transform: translateY(10px);
  }
}
```

**Fallback (progressive enhancement):**

```css
/* Baseline: class/state-driven entry transition */
.card {
  opacity: 0;
  transform: translateY(10px);
  transition: opacity 0.3s, transform 0.3s;
}

.card.is-visible {
  opacity: 1;
  transform: translateY(0);
}
```

```css
/* Enhancement: remove extra visibility class plumbing with @starting-style */
.card {
  opacity: 1;
  transform: translateY(0);
  transition: opacity 0.3s, transform 0.3s;

  @starting-style {
    opacity: 0;
    transform: translateY(10px);
  }
}
```
