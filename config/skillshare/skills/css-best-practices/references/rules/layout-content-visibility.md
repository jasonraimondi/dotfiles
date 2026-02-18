---
title: Content Visibility for Lazy Rendering
impact: HIGH
browser: 93%
bcd_id: css.properties.content-visibility.auto
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/content-visibility
tags: layout, performance, content-visibility, lazy-rendering
---

## Content Visibility for Lazy Rendering

Use `content-visibility: auto` instead of JS IntersectionObserver for off-screen rendering optimization.

**Old (JS IntersectionObserver):**

```js
new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) renderContent(entry.target);
  });
}).observe(el);
```

**Modern:**

```css
.section {
  content-visibility: auto;
  contain-intrinsic-size: auto 500px;
}
```

Browser skips rendering off-screen content entirely. `contain-intrinsic-size` provides estimated dimensions for layout.
