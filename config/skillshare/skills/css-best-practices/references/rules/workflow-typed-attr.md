---
title: Typed Attribute Values with attr()
impact: LOW
browser: 40%
bcd_id: css.types.attr
tags: workflow, attr, typed-attributes, data-attributes, experimental
---

## Typed Attribute Values with attr()

Use typed `attr()` values for simple style bindings instead of JS reading `dataset` values.

**Old (JS dataset -> style):**

```js
const pct = el.dataset.pct;
el.style.width = `${pct}%`;
```

**Modern (experimental):**

```css
.progress-bar {
  width: attr(data-pct type(<percentage>));
}
```

**Fallback (progressive enhancement):**

```css
.progress-bar {
  width: var(--pct, 0%);
}
```

Use JS/server-rendered attributes to set `--pct` in unsupported browsers.
