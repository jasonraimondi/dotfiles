---
title: @layer for Cascade Control
impact: HIGH
browser: 95%
bcd_id: css.at-rules.layer
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/At-rules/@layer
tags: selector, layer, cascade, specificity, important
---

## @layer for Cascade Control

Use `@layer` to define explicit cascade ordering instead of `!important` wars.

**Old (specificity battles):**

```css
.button { color: blue; }
.special .button { color: red; }
.button.override { color: green !important; } /* escalation */
```

**Modern (explicit ordering):**

```css
@layer base, components, utilities;

@layer base {
  a { color: blue; }
}

@layer components {
  .button { color: green; }
}

@layer utilities {
  .text-red { color: red; } /* always wins over base and components */
}
```

Later layers always win over earlier layers regardless of specificity.
