---
title: Aspect Ratio Without Padding Hack
impact: CRITICAL
browser: 96%
bcd_id: css.properties.aspect-ratio
tags: layout, aspect-ratio, responsive, images, video
---

## Aspect Ratio Without Padding Hack

Use `aspect-ratio` instead of the `padding-top` percentage trick.

**Old (padding hack):**

```css
.video-wrapper {
  position: relative;
  padding-top: 56.25%; /* 16:9 */
}
.video-wrapper > * {
  position: absolute;
  inset: 0;
}
```

**Modern:**

```css
.video-wrapper {
  aspect-ratio: 16 / 9;
}
```
