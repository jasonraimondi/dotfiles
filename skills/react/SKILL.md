---
name: react
description: React component structure, state machines, and performance. Use when writing or editing React components, restructuring one that mixes hooks into its JSX, deciding what belongs in the controller vs the view, modeling component state with useReducer, or reviewing or fixing React performance — request waterfalls, bundle size, re-renders, slow rendering.
---

# React

## Controller/view paradigm

Every component with logic is a **controller** that owns the hooks paired with a **view** that owns the markup; a purely presentational component with no logic stays one file.

Read `example/` before writing the first file — it is the ground truth for prop shape, sub-component placement, and how the spec mounts the controller.

```
example/
  api/invites.ts                                  data layer
  components/InviteTeammates/
    InviteTeammates.tsx                           controller, public entry
    InviteTeammates.view.tsx                      view, private
    InviteTeammates.machine.ts                    state machine, pure
    InviteTeammates.spec.tsx                      spec
    components/
      InviteRow.tsx / InviteRow.view.tsx          sub-component pair
      RoleBadge.tsx                               trivial, unsplit
```

- `ComponentName.tsx` exports `ComponentName` — the controller and the public component. Owns data fetching (react-query), the state machine, derived values, and event handlers; returns a single `<ComponentNameView />` with plain props.
- `ComponentName.view.tsx` exports `ComponentNameView`, driven entirely by props. Local UI-only state (open/close, hover) belongs here.
- Consumers import from `ComponentName/ComponentName`, so the public name resolves to a real declaration for grep, go-to-definition, and rename-symbol. No `index.tsx` barrel, no aliased re-exports.
- Sub-components live in `components/` beside their parent and follow the same split. Start as a flat `Name.tsx` / `Name.view.tsx` pair; promote to a directory once one needs children of its own.
- `ComponentName.spec.tsx` mounts the controller and stubs the api module, so one spec exercises the real hooks against the real view.

The split is right when the view file imports nothing from `api/` or react-query, and the controller file holds no markup beyond its single view element.

## State machines

Client state is a **state machine** run through `useReducer`: a discriminated union of states, a union of events, and a pure reducer. One tagged state replaces the cluster of booleans and nullable ids that drift into impossible combinations; if the types allow a state the UI cannot be in, the model is wrong.

- `ComponentName.machine.ts` exports the state type, event type, initial state, and reducer. Plain TypeScript: nothing from React, `api/`, or react-query.
- The reducer switches on the current state, then the event. An event the current state does not handle returns `state` unchanged, so stray clicks and double submits fall out as no-ops.
- Events are past-tense facts (`revokeRequested`, `cancelled`), never setters. View callbacks dispatch events; the controller runs side effects (mutations, navigation) in the handler that dispatches, reading the pre-transition state. The reducer stays pure.
- Each state carries only the data that is meaningful in it: `{ status: "confirming"; inviteId }` has an id because only confirming needs one.
- Server state and mutation status stay in react-query; the machine holds what the user is doing.
- `useState` is for one independent value, like a search string. The moment a second value depends on it, or a boolean is only meaningful in some modes, it becomes a machine.
- A machine with nested or parallel states, guards, or a lifecycle that needs specifying gets designed with the `state-machines` skill before the reducer is written.

## Performance

`references/performance.md` indexes the performance rules by category in impact order; each rule is one file in `references/rules/` with an incorrect/correct pair. Read the index when the task is a performance review or fix, or when the code being written fetches data, awaits more than once, lazy-loads, renders a long list, or runs in a hot path. Then read only the rule files that match.
