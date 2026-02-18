---
title: Popover Hints for Tooltips
impact: MEDIUM
browser: 70%
bcd_id: html.global_attributes.popover.hint
tags: interactive, tooltip, popover-hint, hover
---

## Popover Hints for Tooltips

Use `popover="hint"` with `interestfor` instead of JS mouseenter/mouseleave handlers.

**Old (JS events):**

```js
trigger.addEventListener("mouseenter", () => showTooltip());
trigger.addEventListener("mouseleave", () => hideTooltip());
// Plus: positioning logic, delay handling, etc.
```

**Modern:**

```html
<button interestfor="tip">Hover me</button>
<div id="tip" popover="hint">Tooltip text</div>
```

**Fallback (progressive enhancement):**

```html
<button title="Tooltip text">Hover me</button>
```

Use `title` or an existing JS tooltip fallback where `popover="hint"` is unavailable.
