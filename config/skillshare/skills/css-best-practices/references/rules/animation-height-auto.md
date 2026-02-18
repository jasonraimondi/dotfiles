---
title: Smooth Height Auto Animations
impact: HIGH
browser: 69%
bcd_id: css.properties.interpolate-size.allow-keywords
tags: animation, transition, height-auto, accordion
---

## Smooth Height Auto Animations

Use `interpolate-size: allow-keywords` to animate to/from `height: auto` without JS.

**Old (JS scrollHeight measurement):**

```js
el.style.height = el.scrollHeight + "px";
el.addEventListener("transitionend", () => {
  el.style.height = "auto";
});
```

**Modern:**

```css
:root {
  interpolate-size: allow-keywords;
}

.accordion {
  height: 0;
  overflow: hidden;
  transition: height 0.3s ease;
}

.accordion.open {
  height: auto;
}
```

**Fallback (progressive enhancement):**

```css
/* Baseline fallback */
.accordion {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.3s ease;
}

.accordion.open {
  max-height: 40rem;
}

/* Upgrade when interpolate-size is supported */
@supports (interpolate-size: allow-keywords) {
  .accordion {
    max-height: none;
    height: 0;
    transition: height 0.3s ease;
  }

  .accordion.open {
    height: auto;
  }
}
```
