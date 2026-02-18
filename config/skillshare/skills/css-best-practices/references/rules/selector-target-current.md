---
title: :target-current Scroll Spy
impact: MEDIUM
browser: 60%
bcd_id: css.selectors.target-current
tags: selector, scroll-spy, navigation, target
---

## :target-current Scroll Spy

Use `:target-current` instead of JS IntersectionObserver for scroll spy navigation.

**Old (15+ lines of JS):**

```js
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    const link = document.querySelector(`a[href="#${entry.target.id}"]`);
    link?.classList.toggle("active", entry.isIntersecting);
  });
}, { threshold: 0.5 });
document.querySelectorAll("section").forEach((s) => observer.observe(s));
```

**Modern:**

```css
.nav a:target-current {
  color: var(--accent);
  font-weight: bold;
}
```

**Fallback (progressive enhancement):**

```css
/* Baseline fallback: JS/server sets aria-current="true" */
.nav a[aria-current="true"] {
  color: var(--accent);
  font-weight: bold;
}
```

Upgrade to `:target-current` when supported.
