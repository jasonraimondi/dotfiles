---
title: @property for Typed Custom Properties
impact: HIGH
browser: 92%
bcd_id: css.at-rules.property
tags: workflow, property, typed, animation, custom-properties
---

## @property for Typed Custom Properties

Use `@property` to type custom properties, enabling animation and validation.

**Old (string custom properties — no animation):**

```css
:root { --hue: 0; }
.gradient { background: hsl(var(--hue), 80%, 60%); }
/* --hue cannot be animated — it's a string */
```

**Modern (typed — animatable):**

```css
@property --hue {
  syntax: "<angle>";
  inherits: false;
  initial-value: 0deg;
}

.gradient {
  --hue: 0deg;
  background: oklch(0.7 0.15 var(--hue));
  transition: --hue 0.5s;
}

.gradient:hover {
  --hue: 180deg;
}
```

Supported syntaxes: `<angle>`, `<color>`, `<length>`, `<number>`, `<percentage>`, `<integer>`, etc.
