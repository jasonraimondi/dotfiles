---
title: Stretch Width Without Calc Workarounds
impact: MEDIUM
browser: 70%
bcd_id: css.properties.width.stretch
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Properties/width
tags: layout, width, stretch, sizing
---

## Stretch Width Without Calc Workarounds

Use `width: stretch` instead of `calc(100% - margins)`.

**Old:**

```css
.full-width {
  width: calc(100% - 40px);
}
```

**Modern:**

```css
.full-width {
  width: stretch;
}
```

Fills available container space while respecting margins and padding.

**Fallback (progressive enhancement):**

```css
.full-width {
  width: 100%;
  box-sizing: border-box;
}

@supports (width: stretch) {
  .full-width {
    width: stretch;
  }
}
```
