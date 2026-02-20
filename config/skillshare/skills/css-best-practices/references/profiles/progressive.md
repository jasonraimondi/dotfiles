# Progressive Profile (Tier B)

Use when the user accepts progressive enhancement and fallbacks.

> Tier B list is sourced from rule frontmatter (`tier: B`). Keep robust baseline styles, then layer enhancement with `@supports`.

## Tier B Rules

- `animation-display-none.md`
- `animation-entry.md`
- `animation-scroll-driven.md`
- `animation-view-transitions.md`
- `color-light-dark.md`
- `color-mix.md`
- `color-relative-syntax.md`
- `interactive-light-dismiss.md`
- `interactive-popover.md`
- `layout-subgrid.md`
- `selector-user-invalid.md`
- `typography-text-wrap.md`
- `workflow-scope.md`

## Fallback Pattern

```css
/* Baseline */
.component {
  /* broadly supported styles */
}

/* Enhancement */
@supports (feature: value) {
  .component {
    /* progressive styles */
  }
}
```

## Notes

- Prefer this profile only after Tier A options are considered.
- Avoid stacking many B-tier features in one component unless necessary.
