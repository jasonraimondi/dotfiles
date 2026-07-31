---
description: Use when writing react
---

# Controller/view paradigm

New non-trivial frontend components split logic from presentation. Canonical reference: `web/frontend/src/components/BillingSettings2026/components/*`.

- `ComponentName/ComponentName.tsx` — exports `ComponentName`. This is the controller and the public component: owns all hooks — data fetching (react-query), state, derived values, event handlers — and renders `ComponentNameView` with plain props.
- `ComponentName/ComponentName.view.tsx` — exports `ComponentNameView`. Presentational, driven entirely by props. Local UI-only state (open/close, hover) is fine here.
- No `index.tsx` barrel and no aliased re-exports. Consumers import `ComponentName` from `ComponentName/ComponentName` so the public name resolves to a real declaration for grep, go-to-definition, and rename-symbol.
- The `.view` suffix marks the private half; the unsuffixed file is always the public entry point.
- Tests target the controller: `ComponentName.spec.tsx`.
- A component with no sub-components or local hooks can live as two flat files (`components/ComponentName.tsx`, `components/ComponentName.view.tsx`); promote to a directory once it needs one.
- Skip the split for trivial purely-presentational components — a single file is fine when there is no logic to separate.
