---
title: Object-Fit for Responsive Images
impact: HIGH
browser: 97%
tier: A
bcd_id: css.properties.object-fit.cover
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/object-fit
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
