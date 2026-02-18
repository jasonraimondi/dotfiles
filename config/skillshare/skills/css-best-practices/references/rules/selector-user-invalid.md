---
title: :user-invalid Form Validation
impact: HIGH
browser: 85%
bcd_id: css.selectors.user-invalid
tags: selector, forms, validation, user-invalid
---

## :user-invalid Form Validation

Use `:user-invalid` / `:user-valid` instead of JS `.touched` class patterns.

**Old (JS touched pattern):**

```js
el.addEventListener("blur", () => el.classList.add("touched"));
```

```css
.touched:invalid { border-color: red; }
```

**Modern:**

```css
input:user-invalid {
  border-color: red;
}

input:user-valid {
  border-color: green;
}
```

Only triggers after user interaction — won't flash red on page load.
