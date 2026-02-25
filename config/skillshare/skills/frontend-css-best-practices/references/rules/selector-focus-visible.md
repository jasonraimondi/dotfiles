---
title: :focus-visible for Keyboard-Only Focus
impact: HIGH
browser: 96%
tier: A
bcd_id: css.selectors.focus-visible
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/Selectors/:focus-visible
tags: selector, focus, accessibility, keyboard
---

## :focus-visible for Keyboard-Only Focus

Use `:focus-visible` instead of `:focus` to show outlines only for keyboard navigation.

**Old (shows on mouse click too):**

```css
button:focus {
  outline: 2px solid blue;
}
```

**Modern (keyboard only):**

```css
button:focus-visible {
  outline: 2px solid var(--focus-ring);
  outline-offset: 2px;
}
```
