---
title: Subgrid for Nested Grid Alignment
impact: HIGH
browser: 88%
bcd_id: css.properties.grid-template-columns.subgrid
tags: layout, grid, subgrid, alignment
---

## Subgrid for Nested Grid Alignment

Use `subgrid` instead of duplicating parent track definitions in child grids.

**Old (duplicated tracks):**

```css
.parent {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr;
}
.child {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr; /* duplicated */
}
```

**Modern (subgrid):**

```css
.parent {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr;
}
.child {
  display: grid;
  grid-column: span 3;
  grid-template-columns: subgrid;
}
```
