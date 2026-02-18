---
title: Container Queries Instead of Media Queries
impact: CRITICAL
browser: 92%
bcd_id: css.at-rules.container
tags: layout, container-queries, responsive, components
---

## Container Queries Instead of Media Queries

Use `@container` for component-level responsive design instead of viewport-based `@media`.

**Old (viewport-based):**

```css
@media (max-width: 768px) {
  .card {
    flex-direction: column;
  }
}
```

**Modern (container-based):**

```css
.card-container {
  container-type: inline-size;
}

@container (width < 400px) {
  .card {
    flex-direction: column;
  }
}
```

Components adapt to their container size, not the viewport. Works anywhere the component is placed.
