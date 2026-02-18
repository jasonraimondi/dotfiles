---
title: Variable Fonts
impact: MEDIUM
browser: 96%
bcd_id: css.properties.font-variation-settings
tags: typography, variable-fonts, font-weight, performance
---

## Variable Fonts

Use one variable font file instead of separate @font-face per weight.

**Old (multiple files):**

```css
@font-face { font-family: "Inter"; src: url("inter-400.woff2"); font-weight: 400; }
@font-face { font-family: "Inter"; src: url("inter-500.woff2"); font-weight: 500; }
@font-face { font-family: "Inter"; src: url("inter-700.woff2"); font-weight: 700; }
```

**Modern (one file, any weight):**

```css
@font-face {
  font-family: "Inter";
  src: url("inter-variable.woff2");
  font-weight: 100 900;
}

.semibold { font-weight: 600; }
.custom { font-weight: 650; } /* any value in range */
```
