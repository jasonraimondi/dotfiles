---
title: CSS Anchor Positioning
impact: HIGH
browser: 75%
bcd_id: css.properties.position-anchor
tags: interactive, anchor, positioning, tooltip, popover
---

## CSS Anchor Positioning

Use CSS anchor positioning instead of Popper.js / Floating UI.

**Old (Popper.js):**

```js
import { createPopper } from "@popperjs/core";
createPopper(trigger, tooltip, { placement: "top" });
// Recalculates on scroll, resize, mutation...
```

**Modern:**

```css
.trigger {
  anchor-name: --btn;
}

.tooltip {
  position-anchor: --btn;
  inset-area: top;
}
```

**Fallback (progressive enhancement):**

```css
/* Baseline absolute-position fallback */
.trigger {
  position: relative;
}

.tooltip {
  position: absolute;
  inset-block-end: calc(100% + 8px);
  inset-inline-start: 50%;
  transform: translateX(-50%);
}

/* Upgrade when anchor positioning is supported */
@supports (position-anchor: --btn) {
  .trigger {
    anchor-name: --btn;
  }

  .tooltip {
    position-anchor: --btn;
    inset-area: top;
    transform: none;
  }
}
```
