---
title: Scroll-Linked Animations
impact: HIGH
browser: 82%
bcd_id: css.properties.animation-timeline.view
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/animation-timeline/view
tags: animation, scroll, scroll-timeline, parallax
---

## Scroll-Linked Animations

Use `animation-timeline: view()` instead of JS IntersectionObserver with manual transforms.

**Old (JS IntersectionObserver):**

```js
new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    entry.target.style.opacity = entry.intersectionRatio;
  });
}, { threshold: [...Array(100).keys()].map((i) => i / 100) });
```

**Modern:**

```css
.fade-in {
  animation: fadeIn linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}
```

### Notes & Caveats
- Animations run on the compositor thread for smooth scrolling, but only if you animate compositor-friendly properties (e.g., `opacity`, `transform`, `filter`).
- Avoid animating layout properties like `width`, `height`, or `top`/`left` with scroll timelines.

**Fallback (progressive enhancement):**

```css
/* Baseline: readable content with no scroll-linked effect */
.fade-in {
  opacity: 1;
  transform: none;
}

/* Upgrade when view timelines are supported */
@supports (animation-timeline: view()) {
  .fade-in {
    opacity: 0;
    animation: fadeIn linear both;
    animation-timeline: view();
    animation-range: entry 0% entry 100%;
  }
}
```
