---
title: Light Dismiss for Dialogs
impact: MEDIUM
browser: 80%
bcd_id: html.elements.dialog.closedby
mdn_url: https://developer.mozilla.org/docs/Web/HTML/Reference/Elements/dialog
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

**Fallback (progressive enhancement):**

```js
// Baseline fallback: click-outside close behavior in JS
const dialog = document.querySelector('dialog');

dialog?.addEventListener('click', (e) => {
  const rect = dialog.getBoundingClientRect();
  const outside =
    e.clientX < rect.left ||
    e.clientX > rect.right ||
    e.clientY < rect.top ||
    e.clientY > rect.bottom;

  if (outside) dialog.close();
});
```

When `closedby="any"` is supported, remove this listener and rely on native light-dismiss.
