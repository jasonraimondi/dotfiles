---
title: Gap Instead of Margin Hacks
impact: CRITICAL
browser: 96%
bcd_id: css.properties.gap
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/gap
tags: layout, spacing, flexbox, grid, gap
---

## Gap Instead of Margin Hacks

Use flexbox/grid `gap` instead of margin on children with last-child overrides.

**Old (margin hack):**

```css
.stack > * {
  margin-bottom: 16px;
}
.stack > *:last-child {
  margin-bottom: 0;
}
```

**Modern (gap):**

```css
.stack {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
```

Works with both flexbox and grid. No need for `:last-child` or `:first-child` overrides.
