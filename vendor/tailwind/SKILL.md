---
name: tailwind
description: Produce idiomatic Tailwind CSS with utility-first composition, theme/token alignment, and minimal `@apply` usage. Use for utility class authoring, Tailwind theme/config work, refactoring class soup, mapping vanilla CSS to Tailwind utilities, and aligning Tailwind output with the project's design tokens. Do not use for non-Tailwind CSS work — defer to `best-practices-css` for cascade, accessibility, and motion concepts.
disable-model-invocation: true
---

# Tailwind Best Practices

Produce idiomatic, token-aligned Tailwind CSS. Cross-cutting CSS concepts (cascade, accessibility, motion, logical properties, container queries) defer to `best-practices-css`.

## Defaults

- **Output:** Tailwind utility classes; respect the project's Tailwind config or `@theme` block.
- **`@apply`:** sparingly — only for repeating utility groupings tied to a semantic component class.
- **Recommendations:** one primary solution per problem.

## Workflow

1. **Classify** — utility composition, theme/config edit, `@apply` refactor, or vanilla CSS → Tailwind translation.
2. **Read project config** — locate `tailwind.config.*` or `@theme` block. Match output to existing tokens (colors, spacing, radii, fonts, breakpoints).
3. **Compose with utilities first.** Reach for `@apply` only when a class group recurs across many components and earns its own primitive.
4. **Implement** — provide a patch-level diff (HTML/JSX class lists or `@apply` blocks).
5. **Quality check:**
   - Class lists stay readable (group by concern: layout → spacing → typography → color → state)
   - No arbitrary values when a theme token covers the case
   - States use Tailwind variant prefixes (`hover:`, `focus-visible:`, `data-[state=open]:`), not custom selectors
   - Motion respects `prefers-reduced-motion` (`motion-safe:` / `motion-reduce:`)
   - Accessibility unchanged (focus rings, semantic markup)

## Core Principles

1. **Token alignment.** Every color, size, spacing, and radius comes from the theme. Arbitrary values (`[14px]`, `[#abc123]`) signal a missing token; add it to the theme instead.
2. **Utility-first.** A long class list is fine when it's the source of truth. Don't extract prematurely.
3. **`@apply` sparingly.** Use it for genuine reuse (component primitives), not for hiding utility chains. Each `@apply` block is a CSS rule that escapes Tailwind's compositional model.
4. **Variant prefixes for state.** `hover:`, `focus-visible:`, `disabled:`, `aria-*:`, `data-[*]:`, `dark:`, `motion-reduce:`. Don't write a custom selector when a variant fits.
5. **Responsive prefixes.** Use breakpoint prefixes (`sm:`, `md:`, `lg:`) for viewport. For component-size constraints, use container variants (`@container`, `@md:`) instead.
6. **Predictable class order.** layout → flex/grid → spacing → sizing → typography → color → effects → state variants. Let `prettier-plugin-tailwindcss` enforce it.
7. **Theme extension over override.** Add new tokens via `theme.extend` (or `@theme` in v4). Don't replace defaults unless the design system explicitly drops them.
8. **Compose conditionals with `clsx` / `cva` / `tailwind-variants`.** Don't string-concatenate classes.

## Output Format

1. **Recommendation** — class list or `@apply` block
2. **Why** — token alignment, readability, removed `@apply` overhead
3. **Code patch** — copy-paste ready

## Anti-Patterns

- Arbitrary values when a theme token exists (`[14px]` instead of `text-sm`)
- `@apply` chains used to hide utility soup behind a wrapper class
- Custom CSS selectors for states Tailwind variants already cover
- Ignoring `prettier-plugin-tailwindcss` ordering when the project uses it
- String concatenation for conditional classes
- Replicating cascade/specificity reasoning here when `best-practices-css` is authoritative

## See Also

- `best-practices-css` — cascade, custom-property tokens, accessibility, motion, logical properties, container queries
