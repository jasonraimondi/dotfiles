---
title: Subgrid for Nested Grid Alignment
impact: HIGH
browser: 88%
bcd_id: css.properties.grid-template-columns.subgrid
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Guides/Grid_layout/Subgrid
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

### Notes & Caveats
- `subgrid` requires the parent element to be a grid container (`display: grid` or `display: inline-grid`).
- The child element using `subgrid` must span across the tracks it intends to use (e.g., `grid-column: span 3`).
- If the parent grid tracks change, the subgrid automatically adapts.

**Fallback (progressive enhancement):**

```css
/* Baseline: duplicate parent tracks */
.parent {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr;
}

.child {
  display: grid;
  grid-column: span 3;
  grid-template-columns: 1fr 2fr 1fr;
}

/* Upgrade when subgrid is supported */
@supports (grid-template-columns: subgrid) {
  .child {
    grid-template-columns: subgrid;
  }
}
```
