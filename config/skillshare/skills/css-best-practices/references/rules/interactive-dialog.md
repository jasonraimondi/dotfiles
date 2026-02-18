---
title: Native Dialog Element
impact: HIGH
browser: 96%
bcd_id: html.elements.dialog
tags: interactive, dialog, modal, accessibility
---

## Native Dialog Element

Use `<dialog>` instead of custom modal libraries with z-index management, ESC handling, and focus traps.

**Old (custom modal):**

```js
overlay.style.display = "block";
modal.style.display = "block";
document.addEventListener("keydown", handleEsc);
trapFocus(modal);
```

**Modern:**

```html
<button commandfor="my-dialog" command="show-modal">Open</button>

<dialog id="my-dialog">
  <h2>Modal Title</h2>
  <p>Content here</p>
  <button commandfor="my-dialog" command="close">Close</button>
</dialog>
```

```css
dialog::backdrop {
  background: rgba(0, 0, 0, 0.5);
}

dialog[open] {
  animation: fadeIn 0.2s ease;
}
```

Built-in: focus trap, ESC to close, backdrop, `::backdrop` pseudo-element.
