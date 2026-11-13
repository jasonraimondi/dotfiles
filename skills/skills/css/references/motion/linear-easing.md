# `linear()` Easing

Use `linear()` when you need explicit control over velocity across the duration: nuanced accelerate/decelerate segments, spring-like settle without a JS spring runtime, or shared motion tokens with a recognizable signature.

Token definitions: `tokens.css`.

## Design workflow

1. Name the perception goal — snappy settle, soft settle, assertive emphasis.
2. Start at 4 points; go to 6–8 only when the extra inflection is visible.
3. Keep every inflection point intentional.
4. Validate in real UI, not only an isolated demo.

## Applied examples

### Card enter — soft, readable

```css
.card {
  transition:
    opacity var(--motion-duration-normal) var(--ease-linear-soft),
    translate var(--motion-duration-normal) var(--ease-linear-soft);
}

.card[data-state="from-below"] {
  opacity: 0;
  translate: 0 var(--motion-distance-sm);
}
```

### Popover exit — crisp, fast

```css
.popover {
  transition:
    opacity var(--motion-duration-quick) var(--ease-linear-exit-crisp),
    transform var(--motion-duration-quick) var(--ease-linear-exit-crisp);
}

.popover[data-state="closed"] {
  opacity: 0;
  transform: translateY(-4px) scale(0.985);
}
```

### Shared element settle — route/state continuity

```css
::view-transition-group(card-image) {
  animation-duration: var(--motion-duration-route);
  animation-timing-function: var(--ease-linear-settle-gentle);
}
```

### CTA emphasis — single pulse, non-looping

```css
@keyframes cta-pulse {
  0% { scale: 1; }
  55% { scale: 1.04; }
  100% { scale: 1; }
}

.cta[data-emphasis="true"] {
  animation: cta-pulse var(--motion-duration-normal) var(--ease-linear-emphasis) 1;
}
```

### Progress indicator — constant velocity

The `linear` keyword, not the function.

```css
.progress-bar {
  transition: inline-size var(--motion-duration-structural) linear;
}
```

## Pairing

| Interaction | Easing |
| --- | --- |
| Enter | `--ease-linear-soft` or `--ease-standard` |
| Exit | `--ease-linear-exit-crisp` or `--ease-exit`, at a shorter duration |
| Emphasis | `--ease-linear-emphasis`, short duration |
| Shared element | `--ease-linear-settle-gentle`, 280–380ms |

## Common mistakes

- More points than the UX benefit justifies
- A bespoke curve per component instead of a shared token
- Long durations with complex curves on frequent interactions
- `linear()` where constant velocity (`linear`) is the actual intent
