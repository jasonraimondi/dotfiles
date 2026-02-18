---
title: Native CSS @function
impact: MEDIUM
browser: 50%
bcd_id: css.at-rules.function
mdn_url: https://developer.mozilla.org/docs/Web/CSS/Reference/At-rules/@function
tags: workflow, function, sass-mixin, preprocessor, experimental
---

## Native CSS @function (Experimental)

Use native CSS `@function` instead of Sass `@function` / `@mixin`.

**Old (Sass):**

```scss
@function fluid-size($min, $max) {
  @return clamp($min, calc($min + ($max - $min) * (100vw - 320px) / 1280), $max);
}
h1 { font-size: fluid-size(2rem, 4rem); }
```

**Modern (experimental):**

```css
@function --fluid-size(--min, --max) {
  @return clamp(var(--min), calc(var(--min) + (var(--max) - var(--min)) * (100vw - 320px) / 1280), var(--max));
}

h1 {
  font-size: --fluid-size(2rem, 4rem);
}
```

**Fallback (progressive enhancement):**

```css
h1 {
  font-size: clamp(2rem, calc(2rem + (4rem - 2rem) * (100vw - 320px) / 1280), 4rem);
}
```

Use direct `clamp()` values (or build-time Sass functions) as the baseline.

Note: Limited browser support as of 2026. Use with progressive enhancement.
