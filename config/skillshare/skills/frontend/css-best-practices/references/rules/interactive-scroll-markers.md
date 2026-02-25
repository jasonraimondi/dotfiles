---
title: Scroll Buttons & Markers for Carousel Navigation
impact: MEDIUM
browser: 60%
tier: C
bcd_id: css.selectors.scroll-button
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Selectors/::scroll-button
tags: interactive, carousel, scroll-button, scroll-marker
---

## Scroll Buttons & Markers for Carousel Navigation

Use `::scroll-button()` and `::scroll-marker` pseudo-elements instead of carousel library navigation.

**Old (carousel library):**

```js
new Swiper(".carousel", {
  navigation: { nextEl: ".next", prevEl: ".prev" },
  pagination: { el: ".dots" },
});
```

**Modern:**

```css
.carousel::scroll-button(inline-start) {
  content: "←";
}

.carousel::scroll-button(inline-end) {
  content: "→";
}

.carousel .slide::scroll-marker {
  content: "●";
}
```

**Fallback (progressive enhancement):**

```css
/* Baseline fallback: keep scroll-snap + custom buttons */
.carousel {
  overflow-x: auto;
  scroll-snap-type: x mandatory;
}

.slide {
  scroll-snap-align: start;
}
```

Keep existing JS/HTML prev-next controls for browsers without `::scroll-button()`/`::scroll-marker`.
