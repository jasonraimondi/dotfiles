---
title: Inline CSS Conditionals
impact: MEDIUM
browser: 45%
tier: C
bcd_id: css.types.if
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Values/if
tags: workflow, if, conditionals, style-queries, experimental
---

## Inline CSS Conditionals (Experimental)

Use `if()` for inline conditional styles instead of JS class toggling.

**Old (JS class toggle):**

```js
el.classList.toggle("primary", variant === "primary");
```

**Modern (experimental):**

```css
.button {
  background: if(style(--variant: primary): var(--blue); else: var(--gray));
}
```

**Fallback (progressive enhancement):**

```css
.button {
  background: var(--button-bg, var(--gray));
}

.button[data-variant="primary"] {
  --button-bg: var(--blue);
}
```

Use classes/data-attributes + custom properties as the baseline.

Note: Very limited browser support as of 2026. Use with progressive enhancement.
