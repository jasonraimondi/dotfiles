---
title: Range Style Queries
impact: LOW
browser: 35%
bcd_id: css.at-rules.container.style_queries_for_custom_properties.range_syntax
tags: workflow, style-queries, range, container-queries, experimental
---

## Range Style Queries

Use range style queries to react to custom property thresholds without JS class toggles.

**Old (JS class toggles):**

```js
bar.classList.toggle("is-high", progress > 50);
```

**Modern (experimental):**

```css
@container style(--progress > 50%) {
  .bar {
    background: green;
  }
}
```

**Fallback (progressive enhancement):**

```css
.bar {
  background: orange;
}

.bar.is-high {
  background: green;
}
```

Keep a class/data-attribute fallback for browsers without style query support.
