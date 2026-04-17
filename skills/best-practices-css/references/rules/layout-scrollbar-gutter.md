---
title: Scrollbar Gutter to Prevent Layout Shift
impact: MEDIUM
browser: 90%
tier: A
bcd_id: css.properties.scrollbar-gutter.stable
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/scrollbar-gutter
tags: layout, scrollbar, layout-shift, cls
---

## Scrollbar Gutter to Prevent Layout Shift

Use `scrollbar-gutter: stable` instead of `overflow-y: scroll` or padding hacks.

**Old:**

```css
body {
  overflow-y: scroll; /* always show scrollbar */
}
/* or */
body {
  padding-right: 17px; /* hardcoded scrollbar width */
}
```

**Modern:**

```css
body {
  scrollbar-gutter: stable;
}
```

Reserves space for the scrollbar without showing it, preventing content shift.
