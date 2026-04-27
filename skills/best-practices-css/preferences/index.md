## Major

The architectural rules. Following these keeps the bones of the codebase sound.

1. **A component renders correctly in isolation.** Drop it onto a blank page and it should look the same as it does in situ. Its styles travel with it.

2. **Reference design tokens via CSS custom properties.** Colors, font families, font sizes, shadows, spacing, radii, and z-indexes are always `var(--*)` lookups. The token registry is the single source of truth.

3. **Express variants by overriding the variable that downstream properties read from.** A `button[data-variant="danger"]` rule sets `--button-bg`. Borders, shadows, and hover states stay in sync because they all derive from the same token. A clean variant block contains one or two declarations.

4. **Resolve specificity conflicts through `@layer` ordering.** Place a rule in the layer where it needs to win, and let cascade order do the work.

5. **Reach for intrinsic layout first.** `grid`, `flex-wrap`, `auto-fit`, `auto-fill`, `minmax()`, and `clamp()` carry most responsive behavior. Media queries handle what genuinely needs a breakpoint.

6. **Scope styles to their component.** Use SFC styles, CSS Modules, or `@scope`. Global CSS holds resets, base typography, and design tokens.

---

## Minor

Strong best practices. These are what distinguish good CSS from passable CSS.

7. **Style raw HTML elements in the base layer.** A page of unclassed HTML (forms, tables, headings, lists) should already look on-brand. Components inherit from base; they do not recreate it.

8. **Define tokens once at `:root` and override at the component level when needed.** The cascade is the feature. Lean on it.

9. **Derive related values from a base token.** Transparent, lighter, or darker variants of a color come from `color-mix()` or relative color syntax against the base.

10. **Use fluid typography with `clamp()`** keyed off viewport or container size. One declaration covers the full range.

11. **Nest queries inside the selector.** One selector owns all its responsive behavior in one place.

12. **Resolve cascade conflicts through `@layer`, not selector chains.** Place rules where they need to win instead of writing `h2.heading` or `div.foo .bar`.

13. **Organize globals into `@layer`s with explicit order.** Suggested order: `reset`, `base`, `tokens`, `components`, `utilities`, `overrides`. Declare the order at the top of the entry stylesheet.

14. **Use `@property` with `inherits: false` for layout primitives.** Variables like `--gap`, `--padding`, and `--columns` stay local to their component instance.

15. **Extract reusable primitives.** Generic patterns (table, heading, section, card) live as components or classes any page can use. A name like `.admin-page-table` signals an extraction.

16. **Compose components from tokens so global changes propagate.** Updating a token should flow through the whole site automatically.

---

## Detail

Refinements, specific techniques, and tooling. These sharpen the edges once the major and minor rules are in place.

17. **Use container queries when component size is what matters.** Reach for media queries when the viewport itself is the constraint.

18. **Use `@scope` with donut scoping when a style block needs a clear upper and lower bound** (e.g. card styles that should stay within their card and stop at any nested card).

19. **Pass variables as inline styles for one-off overrides** (`style="--accent: blue"`). One inline declaration replaces a new selector.

20. **Keep selectors top-level scoped.** When a child component's internals matter, expose a variable or prop for it.

21. **Use scoped styles or data attributes for variants.** Style local elements directly inside their scope; differentiate states with `data-*` attributes.

22. **Configure Stylelint or Biome's CSS linter to enforce token usage.** Color, font-size, shadow, and spacing values must be `var(--*)` references. The linter is the bad guy, so a human doesn't have to be.

23. **Add new design tokens to the central tokens file.** The registry stays the single source of truth.

---

## Pre-flight checklist

Before committing a CSS rule, verify:

- Could this live on a raw element selector in the base layer?
- Is every color, size, shadow, and space referencing a token?
- Could `clamp`, `minmax`, or `auto-fit` handle this responsively?
- For variants: am I overriding a variable that other properties read from?
- For overrides: could `@layer` ordering handle this?
- Does this style stay inside its component, both in what it affects and what it depends on?
