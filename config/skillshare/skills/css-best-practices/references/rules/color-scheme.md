---
title: Color Scheme for Automatic Dark Mode
impact: MEDIUM
browser: 93%
bcd_id: css.properties.color-scheme
tags: color, dark-mode, color-scheme, form-controls
---

## Color Scheme for Automatic Dark Mode

Use `color-scheme: light dark` to let the browser automatically style form controls and scrollbars for dark mode.

**Old (manual media query for controls):**

```css
@media (prefers-color-scheme: dark) {
  input, select, textarea {
    background: #333;
    color: #eee;
    border-color: #555;
  }
}
```

**Modern:**

```css
:root {
  color-scheme: light dark;
}
```

Browser automatically adjusts form controls, scrollbars, and system colors.
