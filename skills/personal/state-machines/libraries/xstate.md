# XState

Implementing a designed machine with XState v5: a full statechart with context, guards, actions, delayed transitions, and input. Verify the current API with the context7-cli skill before writing; XState's API changed substantially between v4 and v5.

## Machine definition

The order lifecycle from `SKILL.md`, with `Delivered` completing on a timer instead of a `returnWindowClosed` event to show a delayed transition.

```typescript
import { createMachine, assign } from 'xstate';

interface OrderContext {
  items: LineItem[];
  customerId: string;
  paymentId?: string;
  trackingNumber?: string;
}

type OrderEvent =
  | { type: 'ITEM_ADDED'; item: LineItem }
  | { type: 'ITEM_REMOVED'; itemId: string }
  | { type: 'ORDER_PLACED' }
  | { type: 'PAYMENT_RECEIVED'; paymentId: string }
  | { type: 'CANCELLATION_REQUESTED' }
  | { type: 'CHANGES_REQUESTED' }
  | { type: 'DISPATCHED'; trackingNumber: string }
  | { type: 'DELIVERY_CONFIRMED' }
  | { type: 'RETURN_REQUESTED' }
  | { type: 'REFUND_ISSUED' }
  | { type: 'RETURN_RECEIVED' };

const orderMachine = createMachine({
  id: 'order',
  types: {} as {
    context: OrderContext;
    events: OrderEvent;
    input: Partial<OrderContext>;
  },
  initial: 'draft',
  context: ({ input }) => ({
    items: [],
    customerId: '',
    ...input,
  }),

  states: {
    draft: {
      entry: 'initializeOrder',
      on: {
        ITEM_ADDED: {
          actions: assign({
            items: ({ context, event }) => [...context.items, event.item],
          }),
        },
        ITEM_REMOVED: {
          actions: assign({
            items: ({ context, event }) =>
              context.items.filter(i => i.id !== event.itemId),
          }),
        },
        ORDER_PLACED: {
          target: 'submitted',
          guard: 'hasItems',
        },
        CANCELLATION_REQUESTED: 'cancelled',
      },
    },

    submitted: {
      entry: 'reserveInventory',
      on: {
        PAYMENT_RECEIVED: {
          target: 'paid',
          guard: 'paymentValid',
          actions: assign({
            paymentId: ({ event }) => event.paymentId,
          }),
        },
        CANCELLATION_REQUESTED: {
          target: 'cancelled',
          actions: 'releaseInventory',
        },
        CHANGES_REQUESTED: 'draft',
      },
    },

    paid: {
      entry: 'confirmInventory',
      on: {
        DISPATCHED: {
          target: 'shipped',
          actions: assign({
            trackingNumber: ({ event }) => event.trackingNumber,
          }),
        },
        REFUND_ISSUED: 'refunded',
      },
    },

    shipped: {
      entry: 'sendTrackingNotification',
      on: {
        DELIVERY_CONFIRMED: 'delivered',
        RETURN_REQUESTED: 'returned',
      },
    },

    delivered: {
      on: {
        RETURN_REQUESTED: 'returned',
      },
      after: {
        returnWindow: 'completed',
      },
    },

    returned: {
      on: {
        RETURN_RECEIVED: 'refunded',
      },
    },

    completed: { type: 'final' },
    cancelled: { type: 'final' },
    refunded: { type: 'final' },
  },
}, {
  guards: {
    hasItems: ({ context }) => context.items.length > 0,
    paymentValid: ({ event }) => event.type === 'PAYMENT_RECEIVED' && !!event.paymentId,
  },
  delays: {
    returnWindow: 14 * 24 * 60 * 60 * 1000,
  },
  actions: {
    initializeOrder: () => console.log('Order initialized'),
    reserveInventory: ({ context }) =>
      console.log(`Reserving ${context.items.length} items`),
    confirmInventory: () => console.log('Inventory confirmed'),
    releaseInventory: () => console.log('Inventory released'),
    sendTrackingNotification: ({ context }) =>
      console.log(`Tracking: ${context.trackingNumber}`),
  },
});
```

## Testing

Drive an actor and assert on its snapshot. Inject spies with `machine.provide` to verify actions without running real side effects.

```typescript
import { describe, it, expect, vi } from 'vitest';
import { createActor } from 'xstate';

describe('order machine (XState)', () => {
  function createOrderActor(input?: Partial<OrderContext>) {
    return createActor(orderMachine, { input });
  }

  describe('transitions', () => {
    it('submits when items exist', () => {
      const actor = createOrderActor();
      actor.start();

      actor.send({ type: 'ITEM_ADDED', item: { id: '1', name: 'Widget', qty: 1 } });
      actor.send({ type: 'ORDER_PLACED' });

      expect(actor.getSnapshot().value).toBe('submitted');
      expect(actor.getSnapshot().context.items).toHaveLength(1);
    });

    it('blocks submit without items (guard)', () => {
      const actor = createOrderActor();
      actor.start();

      actor.send({ type: 'ORDER_PLACED' });

      expect(actor.getSnapshot().value).toBe('draft');
    });
  });

  describe('guards', () => {
    it('blocks payment without paymentId', () => {
      const actor = createOrderActor();
      actor.start();

      actor.send({ type: 'ITEM_ADDED', item: { id: '1', name: 'Widget', qty: 1 } });
      actor.send({ type: 'ORDER_PLACED' });
      actor.send({ type: 'PAYMENT_RECEIVED', paymentId: '' });

      expect(actor.getSnapshot().value).toBe('submitted');
    });
  });

  describe('actions', () => {
    it('calls reserveInventory on entering submitted', () => {
      const reserveInventory = vi.fn();

      const testMachine = orderMachine.provide({
        actions: { reserveInventory },
      });

      const actor = createActor(testMachine);
      actor.start();

      actor.send({ type: 'ITEM_ADDED', item: { id: '1', name: 'Widget', qty: 1 } });
      actor.send({ type: 'ORDER_PLACED' });

      expect(reserveInventory).toHaveBeenCalledOnce();
    });
  });

  describe('context updates', () => {
    it('stores trackingNumber on ship', () => {
      const actor = createOrderActor();
      actor.start();

      actor.send({ type: 'ITEM_ADDED', item: { id: '1', name: 'Widget', qty: 1 } });
      actor.send({ type: 'ORDER_PLACED' });
      actor.send({ type: 'PAYMENT_RECEIVED', paymentId: 'pay_123' });
      actor.send({ type: 'DISPATCHED', trackingNumber: 'TRACK_456' });

      expect(actor.getSnapshot().context.trackingNumber).toBe('TRACK_456');
    });
  });
});
```

## XState-specific checklist

In addition to the general testing checklist in `SKILL.md`:

1. **Action spies**: use `machine.provide({ actions })` to inject mocks and verify calls.
2. **Delays**: override `delays` through `provide` so timed transitions run instantly in tests.
3. **Input over context mutation**: seed test state through `input`, so the machine's `context` factory stays the single place that builds initial context.
4. **Model-based testing**: use `createTestModel` from `@xstate/graph` to generate test paths from the machine definition and reach every state.
