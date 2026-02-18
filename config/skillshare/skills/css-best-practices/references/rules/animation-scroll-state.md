---
title: Scroll State Styling
impact: MEDIUM
browser: 65%
bcd_id: css.at-rules.container.scroll-state_queries.stuck
tags: animation, scroll-state, sticky, snapped
---

## Scroll State Styling

Use `@container scroll-state()` to detect stuck/snapped elements instead of JS scroll listeners.

**Old (JS scroll listener):**

```js
window.addEventListener("scroll", () => {
  const rect = header.getBoundingClientRect();
  header.classList.toggle("stuck", rect.top <= 0);
});
```

**Modern:**

```css
@container scroll-state(stuck: top) {
  .header {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  }
}
```

**Fallback (progressive enhancement):**

```css
/* Baseline fallback: JS/server can set .is-stuck */
.header.is-stuck {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

/* Upgrade when scroll-state container queries are supported */
@supports (container-type: scroll-state) {
  @container scroll-state(stuck: top) {
    .header {
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }
  }
}
```
