---
title: Relative Color Syntax for Variants
impact: HIGH
browser: 87%
bcd_id: css.types.color.color.relative_syntax
tags: color, relative-color, variants, lighten, darken
---

## Relative Color Syntax for Variants

Use relative color syntax instead of Sass `lighten()`/`darken()` functions.

**Old (Sass):**

```scss
.lighter { color: lighten($brand, 20%); }
.darker { color: darken($brand, 10%); }
```

**Modern (relative color syntax):**

```css
.lighter {
  color: oklch(from var(--brand) calc(l + 0.2) c h);
}

.darker {
  color: oklch(from var(--brand) calc(l - 0.1) c h);
}

.more-saturated {
  color: oklch(from var(--brand) l calc(c * 1.5) h);
}

.complementary {
  color: oklch(from var(--brand) l c calc(h + 180));
}
```
