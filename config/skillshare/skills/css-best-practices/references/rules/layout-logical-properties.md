---
title: Logical Properties for Direction-Aware Layouts
impact: HIGH
browser: 95%
bcd_id: css.properties.margin-inline-start
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/margin-inline-start
tags: layout, logical-properties, rtl, i18n, margin, padding
---

## Logical Properties for Direction-Aware Layouts

Use logical properties (`inline-start`, `block-end`) instead of physical (`left`, `right`).

**Old (physical with RTL override):**

```css
.sidebar {
  margin-left: 16px;
}
[dir="rtl"] .sidebar {
  margin-left: 0;
  margin-right: 16px;
}
```

**Modern (logical):**

```css
.sidebar {
  margin-inline-start: 16px;
}
```

Mapping:
- `left`/`right` → `inline-start`/`inline-end`
- `top`/`bottom` → `block-start`/`block-end`
- `margin-left` → `margin-inline-start`
- `padding-top` → `padding-block-start`
- `border-right` → `border-inline-end`
- `width` → `inline-size`
- `height` → `block-size`
