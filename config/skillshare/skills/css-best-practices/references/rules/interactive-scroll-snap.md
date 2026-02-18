---
title: Scroll Snap for Carousels
impact: HIGH
browser: 95%
bcd_id: css.properties.scroll-snap-type
tags: interactive, scroll-snap, carousel, slider
---

## Scroll Snap for Carousels

Use `scroll-snap-type` instead of Swiper/Slick carousel libraries.

**Old (Swiper.js):**

```js
new Swiper(".carousel", {
  slidesPerView: 1,
  spaceBetween: 16,
  navigation: true,
  pagination: true,
});
```

**Modern:**

```css
.carousel {
  display: flex;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  gap: 16px;
}

.slide {
  flex: 0 0 100%;
  scroll-snap-align: start;
}
```
