---
title: Named Grid Areas
impact: MEDIUM
browser: 97%
bcd_id: css.properties.grid-template-areas
tags: layout, grid, grid-template-areas, semantic
---

## Named Grid Areas

Use `grid-template-areas` for semantic, readable grid layouts instead of line numbers.

**Old (line numbers):**

```css
.header {
  grid-column: 1 / 3;
  grid-row: 1;
}
.sidebar {
  grid-column: 1;
  grid-row: 2;
}
```

**Modern (named areas):**

```css
.layout {
  display: grid;
  grid-template-areas:
    "header  header"
    "sidebar main"
    "footer  footer";
}
.header { grid-area: header; }
.sidebar { grid-area: sidebar; }
.main { grid-area: main; }
```
