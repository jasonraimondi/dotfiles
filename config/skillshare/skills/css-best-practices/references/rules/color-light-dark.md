---
title: light-dark() for Dark Mode
impact: HIGH
browser: 83%
bcd_id: css.types.color.light-dark
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Values/color_value/light-dark
tags: color, dark-mode, light-dark, theming
---

## light-dark() for Dark Mode

Use `light-dark()` instead of separate media queries duplicating color values.

**Old (duplicated values):**

```css
:root {
  --bg: #fff;
  --text: #111;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #111;
    --text: #eee;
  }
}
```

**Modern (single declaration):**

```css
:root {
  color-scheme: light dark;
}

.surface {
  background: light-dark(#fff, #111);
  color: light-dark(#111, #eee);
}
```

Requires `color-scheme: light dark` on `:root` or the element.

**Fallback (progressive enhancement):**

```css
/* Baseline: classic media-query tokens */
:root {
  --surface-bg: #fff;
  --surface-text: #111;
}

@media (prefers-color-scheme: dark) {
  :root {
    --surface-bg: #111;
    --surface-text: #eee;
  }
}

.surface {
  background: var(--surface-bg);
  color: var(--surface-text);
}

/* Upgrade when light-dark() is supported */
@supports (color: light-dark(white, black)) {
  :root { color-scheme: light dark; }

  .surface {
    background: light-dark(#fff, #111);
    color: light-dark(#111, #eee);
  }
}
```
