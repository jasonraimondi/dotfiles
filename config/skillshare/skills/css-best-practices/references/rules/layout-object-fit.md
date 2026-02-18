---
title: Object-Fit for Responsive Images
impact: HIGH
browser: 97%
bcd_id: css.properties.object-fit.cover
tags: layout, images, object-fit, responsive
---

## Object-Fit for Responsive Images

Use `object-fit: cover` on semantic `<img>` instead of background-image hacks.

**Old (background-image):**

```css
.hero {
  background-image: url(...);
  background-size: cover;
  background-position: center;
}
```

**Modern (semantic img):**

```css
.hero img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
```

Keeps `<img>` in the DOM for accessibility, SEO, and lazy loading.
