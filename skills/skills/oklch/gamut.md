# Gamut Awareness

## sRGB vs Display P3

Every sRGB color exists within Display P3, but not every P3 color exists within sRGB. Display P3 covers ~50% more colors.

## Max chroma varies by lightness and hue

The gamut boundary is irregular. At L=0.5 in sRGB:

- Highest chroma: purple (H ≈ 285) at C ≈ 0.29
- Red-orange (H ≈ 0-30): C ≈ 0.20
- Lowest chroma: cyan (H ≈ 195) at C ≈ 0.09

The peak hue shifts with lightness. At L=0.7 magenta peaks, at L=0.9 green peaks. Cyan consistently has the lowest max chroma.

## Gamut checking

If a color's chroma exceeds the maximum for its L/H/space, it clips. The fix: reduce chroma while keeping L and H constant.

```css
/* Out of sRGB gamut */
oklch(0.7 0.35 150)

/* Clamped to max chroma */
oklch(0.7 0.22 150)
```

## CSS fallback patterns

```css
/* sRGB fallback for all browsers */
.accent {
  color: oklch(0.7 0.2 150);
}

/* P3 enhancement for wider gamut displays */
@media (color-gamut: p3) {
  .accent {
    color: oklch(0.7 0.3 150);
  }
}
```

For browsers without oklch support:

```css
.accent {
  color: #4ade80;
}

@supports (color: oklch(0 0 0)) {
  .accent {
    color: oklch(0.7 0.2 150);
  }

  @media (color-gamut: p3) {
    .accent {
      color: oklch(0.7 0.3 150);
    }
  }
}
```

