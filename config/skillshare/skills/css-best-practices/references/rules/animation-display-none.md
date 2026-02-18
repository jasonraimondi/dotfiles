---
title: Animating Display None
impact: HIGH
browser: 85%
bcd_id: css.properties.transition-behavior.transitionable_display
tags: animation, transition, display, allow-discrete
---

## Animating Display None

Use `transition-behavior: allow-discrete` to animate elements with `display: none`.

**Old (JS transitionend listener):**

```js
el.addEventListener("transitionend", () => {
  el.style.display = "none";
});
// Plus: visibility + opacity + pointer-events workaround
```

**Modern:**

```css
.panel {
  transition: opacity 0.2s, display 0.2s;
  transition-behavior: allow-discrete;
}

.panel.hidden {
  opacity: 0;
  display: none;
}
```
