# View Transition Recipes

Tier, `bcd_id`, and the `@supports` fallback: `../rules/animation-view-transitions.md`. Tokens: `tokens.css`.

## Same-document (SPA or state swap)

```js
function updateLayout(nextMode) {
  const runUpdate = () => {
    document.documentElement.dataset.layout = nextMode;
  };

  if (!document.startViewTransition) {
    runUpdate();
    return;
  }

  document.startViewTransition(runUpdate);
}
```

```css
::view-transition-old(root),
::view-transition-new(root) {
  animation-duration: var(--motion-duration-structural);
  animation-timing-function: var(--ease-standard);
}

.card__image,
.detail__image {
  view-transition-name: card-image;
}

::view-transition-group(card-image) {
  animation-duration: var(--motion-duration-route);
  animation-timing-function: var(--ease-linear-settle-gentle);
}
```

The two elements sharing `card-image` are never in the document at the same time — a name must be unique for the duration of the transition.

## Cross-document (MPA navigation)

```css
@view-transition {
  navigation: auto;
}

::view-transition-old(root),
::view-transition-new(root) {
  animation-duration: var(--motion-duration-route);
  animation-timing-function: var(--ease-standard);
}
```

Matching elements carry the same `view-transition-name` on both pages.

## Reduced motion

```css
@media (prefers-reduced-motion: reduce) {
  ::view-transition-old(root),
  ::view-transition-new(root),
  ::view-transition-group(*) {
    animation-duration: 1ms;
    animation-timing-function: linear;
  }
}
```

## Rules

- Transition only meaningful shared elements.
- Keep the update callback synchronous and deterministic — DOM or style work inside it becomes a long task.
- The page stays usable when the transition is skipped.
