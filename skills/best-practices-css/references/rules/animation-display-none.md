---
title: Animating Display None
impact: HIGH
browser: 85%
tier: B
bcd_id: css.properties.transition-behavior.transitionable_display
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/transition-behavior
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

**Fallback (progressive enhancement):**

```css
/* Baseline: fade + hide without discrete display transitions */
.panel {
  transition: opacity 0.2s, visibility 0s linear 0.2s;
}

.panel.hidden {
  opacity: 0;
  visibility: hidden;
  pointer-events: none;
}

/* Upgrade when discrete transitions are supported */
@supports (transition-behavior: allow-discrete) {
  .panel {
    transition: opacity 0.2s, display 0.2s;
    transition-behavior: allow-discrete;
  }

  .panel.hidden {
    visibility: visible;
    display: none;
  }
}
```
