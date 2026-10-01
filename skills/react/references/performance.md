# React performance rules

Client-side SPA rules, grouped by category in impact order. Each line names a file in `rules/` holding the incorrect/correct pair. Read the category that matches the problem, then only the rule files that apply.

## Waterfalls — critical

- `async-parallel` — `Promise.all()` for independent operations.
- `async-dependencies` — partially dependent operations start as early as their inputs allow.
- `async-defer-await` — move an `await` into the branch that uses its result.

## Bundle size — critical

- `bundle-barrel-imports` — import from the source file, not a barrel.
- `bundle-conditional` — load a module only when its feature is activated.
- `bundle-preload` — preload a lazy chunk on hover or focus.

## Client data fetching — medium-high

- `client-query-dedup` — fetch through the react-query cache so instances share one request.
- `client-event-listeners` — one shared global listener across component instances.

## Re-renders — medium

- `rerender-defer-reads` — read dynamic state inside the callback that uses it, not at render.
- `rerender-memo` — extract expensive work into a memoized component.
- `rerender-dependencies` — effect dependencies are primitives, not objects.
- `rerender-derived-state` — subscribe to the derived boolean, not the continuous value.
- `rerender-lazy-state-init` — pass a function to `useState` for an expensive initial value.
- `rerender-transitions` — `startTransition` for non-urgent updates.

## Rendering — medium

- `rendering-animate-svg-wrapper` — animate a wrapper element, not the SVG.
- `rendering-content-visibility` — `content-visibility: auto` for long lists.
- `rendering-hoist-jsx` — hoist static JSX out of the component.
- `rendering-svg-precision` — reduce SVG coordinate precision.
- `rendering-activity` — `<Activity>` for show/hide that keeps state.
- `rendering-conditional-render` — ternary, not `&&`, when the condition can be `0` or `NaN`.

## JavaScript hot paths — low-medium

- `js-length-check-first` — compare array lengths before an expensive comparison.
- `js-cache-function-results` — module-level `Map` for repeated calls with the same input.
- `js-batch-dom-css` — batch style changes through a class.
- `js-tosorted-immutable` — `toSorted()` instead of mutating `sort()`.
- `js-index-maps` — build a `Map` once for repeated lookups.
- `js-set-map-lookups` — `Set`/`Map` instead of `includes` in a loop.
- `js-combine-iterations` — one loop instead of several `filter`/`map` passes.
- `js-cache-property-access` — cache deep property access inside a loop.
- `js-cache-storage` — cache `localStorage`, `sessionStorage`, and cookie reads.
- `js-early-exit` — return as soon as the result is known.
- `js-hoist-regexp` — hoist `RegExp` creation out of render.
- `js-min-max-loop` — one loop for min/max instead of a sort.

## Advanced — low

- `advanced-event-handler-refs` — keep a handler in a ref so the subscription stays stable.
- `advanced-use-latest` — `useLatest` for a stable callback that sees fresh values.
