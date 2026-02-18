---
title: Text Box Trim for Optical Centering
impact: MEDIUM
browser: 65%
bcd_id: css.properties.text-box.trim-both
tags: layout, typography, vertical-centering, text-box
---

## Text Box Trim for Optical Centering

Use `text-box` to trim leading/trailing whitespace for true optical vertical centering.

**Old (uneven padding):**

```css
.button {
  padding: 12px 16px; /* visually uneven due to text metrics */
}
```

**Modern:**

```css
.button {
  text-box: trim-both cap alphabetic;
}
```

Trims the extra space above cap-height and below alphabetic baseline.

**Fallback (progressive enhancement):**

```css
.button {
  line-height: 1.2;
  padding-block: 0.6em;
}

@supports (text-box: trim-both cap alphabetic) {
  .button {
    text-box: trim-both cap alphabetic;
    padding-block: 0;
  }
}
```
