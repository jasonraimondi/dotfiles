---
title: Custom Properties Instead of Sass Variables
impact: HIGH
browser: 97%
bcd_id: css.properties.custom-property
tags: workflow, custom-properties, variables, theming
---

## Custom Properties Instead of Sass Variables

Use CSS custom properties (runtime) instead of Sass $variables (compile-time).

**Old (Sass — static):**

```scss
$primary: #7c3aed;
$radius: 8px;
.button { background: $primary; border-radius: $radius; }
// Compiled: values are baked in, no runtime changes
```

**Modern (CSS — runtime):**

```css
:root {
  --primary: oklch(0.55 0.2 264);
  --radius: 8px;
}

.button {
  background: var(--primary);
  border-radius: var(--radius);
}
```

Can be changed at runtime via JS, media queries, or cascade.
