# React

Implementing a designed machine as a plain `useReducer` reducer, with no library. This file maps the design vocabulary (states, events, guards, actions, entry and exit, long-running work, composite states) onto a reducer; where the reducer file lives and how the controller wires it is the react skill's call. Without that skill: `ComponentName.machine.ts` beside the component, run with `useReducer`, side effects in the handler that dispatches.

## Machine definition

The client-side slice of the order lifecycle from `SKILL.md`: the user builds a draft, reviews it, and places it. From `Submitted` on the order is server state, so it is not modeled in the component.

| Design concept | Reducer shape |
|---|---|
| State | One member of a discriminated union on `status`, carrying only the data meaningful in that state |
| Event | One member of a union on `type`, with its payload |
| Transition table row | One `case` in a `switch` on `state.status`, then on `event.type` |
| Guard | A condition inside the case; a failing guard returns `state`. Mutually exclusive guards are an `if`/`else` chain |
| Ignored or rejected cell | `return state`. A reducer never throws: a stray click or double submit is not an error |
| Action that stores a payload | Done in the returned state |
| Action with a side effect | Run by the controller in the handler that dispatches, reading the pre-transition state |
| Entry or exit action | An effect keyed on `state.status`, so every path into or out of the state runs it |
| Long-running server work | The react-query mutation. Its `pending`, `error`, and `success` are that state and its exit events; model the state in the table, do not duplicate it in the reducer |
| Long-running work that is not a server call (timer, animation, multi-step flow) | A reducer state, with its completion, failure, and timeout dispatched as events |
| Composite state | A nested union on a `substatus`, only when the substates handle different events. Substates that differ only by a guard outcome on context (`Empty` / `HasItems`) are a guard |

```typescript
export type LineItem = { id: string; name: string; qty: number };

export type CheckoutState =
  | { status: 'draft'; items: LineItem[] }
  | { status: 'reviewing'; items: LineItem[] }
  | { status: 'submitted'; orderId: string };

export type CheckoutEvent =
  | { type: 'itemAdded'; item: LineItem }
  | { type: 'itemRemoved'; itemId: string }
  | { type: 'reviewRequested' }
  | { type: 'editingResumed' }
  | { type: 'orderPlaced'; orderId: string };

export const initialCheckoutState: CheckoutState = { status: 'draft', items: [] };

export function checkoutMachine(state: CheckoutState, event: CheckoutEvent): CheckoutState {
  switch (state.status) {
    case 'draft':
      switch (event.type) {
        case 'itemAdded':
          return { status: 'draft', items: [...state.items, event.item] };
        case 'itemRemoved':
          return { status: 'draft', items: state.items.filter((i) => i.id !== event.itemId) };
        case 'reviewRequested':
          return state.items.length > 0 ? { status: 'reviewing', items: state.items } : state;
        default:
          return state;
      }
    case 'reviewing':
      switch (event.type) {
        case 'editingResumed':
          return { status: 'draft', items: state.items };
        case 'orderPlaced':
          return { status: 'submitted', orderId: event.orderId };
        default:
          return state;
      }
    case 'submitted':
      return state;
  }
}
```

The `Placing` state from the design is the mutation. The controller starts it from `reviewing`, and the mutation's success is the `orderPlaced` event; its error leaves the user in `reviewing` with the error shown from react-query.

```typescript
const [state, dispatch] = useReducer(checkoutMachine, initialCheckoutState);

const place = useMutation({
  mutationFn: placeOrder,
  onSuccess: (orderId) => dispatch({ type: 'orderPlaced', orderId }),
});

const confirmOrder = () => {
  if (state.status === 'reviewing') place.mutate(state.items);
};
```

The guard sits on the transition into `reviewing`, so the handler that runs the side effect only has to check `state.status`.

## Testing

Test the reducer directly, table-driven from the transition table, including the cells that are ignored. The controller spec covers the wiring.

```typescript
import { describe, it, expect } from 'vitest';

const widget: LineItem = { id: '1', name: 'Widget', qty: 1 };
const draft = (items: LineItem[]): CheckoutState => ({ status: 'draft', items });
const reviewing = (items: LineItem[]): CheckoutState => ({ status: 'reviewing', items });

describe('checkout machine', () => {
  it.each<[CheckoutState, CheckoutEvent, CheckoutState]>([
    [draft([]), { type: 'itemAdded', item: widget }, draft([widget])],
    [draft([widget]), { type: 'itemRemoved', itemId: '1' }, draft([])],
    [draft([widget]), { type: 'reviewRequested' }, reviewing([widget])],
    [reviewing([widget]), { type: 'editingResumed' }, draft([widget])],
    [reviewing([widget]), { type: 'orderPlaced', orderId: 'ord_1' }, { status: 'submitted', orderId: 'ord_1' }],
  ])('%o + %o → %o', (from, event, expected) => {
    expect(checkoutMachine(from, event)).toEqual(expected);
  });

  it.each<[CheckoutState, CheckoutEvent]>([
    [draft([]), { type: 'reviewRequested' }],
    [draft([widget]), { type: 'orderPlaced', orderId: 'ord_1' }],
    [reviewing([widget]), { type: 'itemAdded', item: widget }],
    [{ status: 'submitted', orderId: 'ord_1' }, { type: 'editingResumed' }],
  ])('%o ignores %o', (from, event) => {
    expect(checkoutMachine(from, event)).toBe(from);
  });
});
```

## React-specific checklist

In addition to the general testing checklist in `SKILL.md`:

1. **Exhaustive switch**: switch on `status` with no `default` at the outer level, so adding a state is a type error until every reducer handles it.
2. **Guard placement**: a guard goes on the transition into the state that enables a side effect, so the handler only checks `state.status`.
3. **Ignore, never throw**: every unhandled `(state, event)` pair returns the same `state` object, and the tests assert identity with `toBe`.
4. **One owner per long-running state**: a server call is the mutation, anything else is a reducer state. Never both.
5. **Entry effects**: an effect keyed on `state.status` runs on every entry, including re-entry through a different transition; a handler does not.
