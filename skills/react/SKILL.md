---
name: react
description: Controller/view split for React components. Use when adding a React component, restructuring one that mixes hooks into its JSX, or deciding what belongs in the controller vs the view.
---

# Controller/view paradigm

Every component with logic is a **controller** that owns the hooks paired with a **view** that owns the markup; a purely presentational component with no logic stays one file.

Read `example/` before writing the first file — it is the ground truth for prop shape, sub-component placement, and how the spec mounts the controller.

```
example/
  api/invites.ts                                  data layer
  components/InviteTeammates/
    InviteTeammates.tsx                           controller, public entry
    InviteTeammates.view.tsx                      view, private
    InviteTeammates.spec.tsx                      spec
    components/
      InviteRow.tsx / InviteRow.view.tsx          sub-component pair
      RoleBadge.tsx                               trivial, unsplit
```

- `ComponentName.tsx` exports `ComponentName` — the controller and the public component. Owns data fetching (react-query), state, derived values, and event handlers; returns a single `<ComponentNameView />` with plain props.
- `ComponentName.view.tsx` exports `ComponentNameView`, driven entirely by props. Local UI-only state (open/close, hover) belongs here.
- Consumers import from `ComponentName/ComponentName`, so the public name resolves to a real declaration for grep, go-to-definition, and rename-symbol. No `index.tsx` barrel, no aliased re-exports.
- Sub-components live in `components/` beside their parent and follow the same split. Start as a flat `Name.tsx` / `Name.view.tsx` pair; promote to a directory once one needs children of its own.
- `ComponentName.spec.tsx` mounts the controller and stubs the api module, so one spec exercises the real hooks against the real view.

The split is right when the view file imports nothing from `api/` or react-query, and the controller file holds no markup beyond its single view element.
