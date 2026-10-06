# Motion Design

Motion explains a state change; it does not decorate it. Every motion proposal serves at least one goal:

- **Continuity** — where a thing came from and where it went
- **Feedback** — the action was acknowledged
- **Hierarchy** — what changed most, and why
- **Focus** — attention lands on the right target

Tier, `bcd_id`, and `@supports` fallbacks for individual motion features live in `../rules/animation-*.md`. This file covers the design decisions those rule files do not.

## Mechanism

Choose the lightest mechanism the interaction allows:

| Mechanism | Use for |
| --- | --- |
| CSS transition | state change on one element (hover, open/close, selected) |
| CSS keyframes | multi-stage or repeating timeline (loading, attention pulse, choreography) |
| WAAPI | imperative sequencing, playback control, cancel/reverse tied to app logic |
| View Transitions API | continuity across DOM swaps, route changes, layout-mode changes |

## Transform strategy

- **`translate` / `rotate` / `scale`** — the default. Composable state layers, one channel per interaction, direct token mapping. See `../rules/animation-independent-transforms.md`.
- **`transform` shorthand** — when function order is intentionally coupled, or a function has no individual property.
- **`translate3d()`** — real 3D/perspective work, or a profiled compositor win on a measured bottleneck. As a blanket GPU hack it costs layer memory and adds jank.

## Easing

- `cubic-bezier()` for most product interactions.
- `linear()` for piecewise velocity control: spring-like settle without a JS spring runtime, controlled overshoot, brand motion signatures. Keep to 4–8 points. See `linear-easing.md`.
- The `linear` keyword (not the function) for constant velocity — progress bars, spinners.

Every easing value is a token; per-component curves fragment the motion system. Baseline set: `tokens.css`.

## Timing

| Scope | Duration |
| --- | --- |
| Micro interaction | 120–180ms |
| Component transition | 180–260ms |
| Structural / route transition | 240–420ms |

Exits run faster than enters. Direction follows layout flow. Stagger only when it improves scannability or hierarchy.

## Character

When motion needs personality — squash and stretch, anticipation, follow-through, arcs, exaggeration — see `disney-principles.md`.

## View Transitions

- **Same-document** — wrap the state update in `document.startViewTransition(() => update())`, and feature-detect so the un-transitioned path still updates.
- **Cross-document** — opt in with `@view-transition { navigation: auto; }` and keep `view-transition-name` values consistent across both pages.
- Name only meaningful shared elements. A name must be unique in the document for the duration of the transition.
- Style `::view-transition-old(root)` / `::view-transition-new(root)`, the named equivalents, and `::view-transition-group(name)` explicitly.
- The interaction never waits on the effect.

Recipes: `view-transitions.md`. Tier and fallback: `../rules/animation-view-transitions.md`.

## Performance

- Animate `transform` and `opacity`. Layout-affecting properties (`top`, `left`, `width`, `height`) stay out of frequent interactions.
- Apply `will-change` narrowly and drop it when the motion ends.
- Keep infinite animations off large surfaces.
- Profile before and after: frame stability, long tasks, layer count.

## Reduced motion

Under `@media (prefers-reduced-motion: reduce)`, replace travel and zoom with a fade or an instant state change — the state change stays legible, only the movement goes. `tokens.css` collapses the duration tokens to `1ms` as the baseline. Focus order, focus visibility, and keyboard flow stay correct through and after every transition.

## Output

When editing, state the reduced-motion behavior in a sentence. An advice-only motion answer adds two sections to the skill's Output Format:

- **Motion spec** — trigger, affected elements, duration, easing token, distance
- **Reduced-motion behavior** — what happens under `prefers-reduced-motion: reduce`, and when the API is unsupported

## Pre-flight checklist

- [ ] The motion explains a state change
- [ ] Direction and distance match the spatial context
- [ ] Enter and exit timings are deliberately asymmetric
- [ ] Animated properties are `transform` and `opacity`
- [ ] Duration and easing come from tokens
- [ ] `prefers-reduced-motion: reduce` keeps the state change understandable
- [ ] Focus and keyboard flow survive the transition
- [ ] View transitions feature-detect and fall back
- [ ] Verified at a mobile viewport and under one throttled scenario
- [ ] No tearing, clipping, or timing drift under rapid repeated interaction
