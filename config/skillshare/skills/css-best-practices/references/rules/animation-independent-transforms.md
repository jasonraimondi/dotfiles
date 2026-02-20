---
title: Independent Transform Properties
impact: MEDIUM
browser: 93%
tier: A
bcd_id: css.properties.translate
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/translate
tags: animation, transform, translate, rotate, scale
---

## Independent Transform Properties

Use separate `translate`, `rotate`, `scale` properties instead of the monolithic `transform` shorthand.

**Old (monolithic):**

```css
.card:hover {
  transform: translateY(-4px) rotate(2deg) scale(1.05);
}
```

**Modern (independent, independently animatable):**

```css
.card {
  translate: 0;
  rotate: 0deg;
  scale: 1;
  transition: translate 0.2s, rotate 0.3s, scale 0.2s;
}

.card:hover {
  translate: 0 -4px;
  rotate: 2deg;
  scale: 1.05;
}
```

Each property can have its own timing function and duration.
