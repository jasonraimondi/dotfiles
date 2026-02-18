---
title: Light Dismiss for Dialogs
impact: MEDIUM
browser: 80%
bcd_id: html.elements.dialog.closedby
tags: interactive, dialog, light-dismiss, click-outside
---

## Light Dismiss for Dialogs

Use `closedby="any"` instead of JS click-outside listeners.

**Old (JS click-outside):**

```js
document.addEventListener("click", (e) => {
  const rect = dialog.getBoundingClientRect();
  if (e.clientX < rect.left || e.clientX > rect.right ||
      e.clientY < rect.top || e.clientY > rect.bottom) {
    dialog.close();
  }
});
```

**Modern:**

```html
<dialog closedby="any">
  <p>Click outside to close</p>
</dialog>
```
