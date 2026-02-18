---
title: Popover for Dropdowns
impact: HIGH
browser: 86%
bcd_id: html.global_attributes.popover
tags: interactive, popover, dropdown, menu
---

## Popover for Dropdowns

Use the `popover` attribute instead of JS display toggles with click-outside listeners.

**Old (JS toggle):**

```css
.menu { display: none; }
.menu.open { display: block; }
/* + JS: click handler, click-outside, ESC key, aria attributes */
```

**Modern:**

```html
<button popovertarget="menu">Menu</button>

<div id="menu" popover>
  <a href="/settings">Settings</a>
  <a href="/logout">Logout</a>
</div>
```

Built-in: click-outside dismiss, ESC to close, focus management, top-layer rendering.
