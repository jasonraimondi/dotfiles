---
name: state-machines
description: Statechart and state machine modeling for lifecycle and behavior specification. Use when designing a state machine or statechart, documenting one, implementing one with a library such as XState, or reviewing one for completeness.
---

# State Machine Design Skill

## Overview

Design finite state machines and statecharts for modeling entity lifecycles, workflows, and system behavior. Base all guidance on Harel statechart semantics.

## State Machine Concepts

### Core Elements

| Element | Description | Example |
|---------|-------------|---------|
| State | Condition the system can be in | `Draft`, `Submitted`, `Paid` |
| Transition | Change from one state to another | `Draft → Submitted` |
| Event | Trigger for a transition | `orderPlaced`, `paymentReceived`, `cancellationRequested` |
| Guard | Condition that must be true | `[hasItems]`, `[isValid]` |
| Action | Side effect on transition | `sendNotification`, `updateDatabase` |
| Entry Action | Action when entering state | `onEnter: startTimer` |
| Exit Action | Action when leaving state | `onExit: stopTimer` |

### State Types

```typescript
type StateType =
  | 'initial'    // Starting state (filled circle)
  | 'normal'     // Regular state
  | 'final'      // End state (circle with border)
  | 'composite'  // Contains sub-states
  | 'parallel'   // Concurrent regions
  | 'history'    // Remember last sub-state
  | 'choice';    // Decision point
```

## Workflow

When designing state machines:

1. **Identify entity**: What has the lifecycle?
2. **List states**: Every finite mode the entity can be in. Data that varies within a mode is context, not a state.
3. **Define events**: What triggers state changes, including failures and timeouts?
4. **Map transitions**: Fill the state × event grid. Every cell is a transition, an explicit ignore, or a rejection.
5. **Add guards**: Guards on the same state and event are mutually exclusive.
6. **Define actions**: Setup and teardown go on entry and exit. Work that takes time becomes a state of its own.
7. **Document**: Write the transition table and diagram with [DOCUMENTATION.md](DOCUMENTATION.md)
8. **Implement**: Choose a pattern from Implementation Patterns below
9. **Test**: Verify all transitions, guards, and paths
10. **Review**: Run the completeness checklist below

## Design Principles

1. **Name states as conditions**: `Submitted` not `Submit`
2. **Name events as past-tense facts**: `paymentReceived` not `pay`; a user's intent is `cancellationRequested`, never a setter
3. **Give an event and the state it leads to different roots**: `dispatched` leads to `Shipped`, so the table reads as cause and effect
4. **A state is compressed history**: it holds only the past that changes the next reaction. Flags that pick branches are unnamed states.
5. **Nest when states share transitions**: a substate inherits its superstate's transitions and defines only its differences.
6. **Use parallel regions when two concerns vary independently**: states named with "And" are the smell.
7. **Long-running or fallible work is a state, not an action**: its completion, failure, and timeout are events.
8. **The transition table is the source of truth**: diagram, code, and tests are derived from it.

The reasoning and sources behind these are in [PRINCIPLES.md](PRINCIPLES.md); read it when a rule is not enough to decide.

## Review for Completeness

A machine is complete when every check passes:

- **Grid**: every (state, event) pair is decided: transition, ignore, or reject.
- **Determinism**: at most one transition is enabled per state and event.
- **No deadlock**: every non-final state has a transition out, and every state reaches a final state.
- **Invariants**: each stated invariant holds in the initial state and is preserved by every transition.
- **Failure paths**: every action that can fail or time out has its failure and timeout as events with transitions.
- **Hierarchy**: each substate behaves consistently with its superstate's transitions.
- **Entry and exit**: no setup or teardown sits on one transition when another path into or out of the state skips it.

## Implementation Patterns

### Transition Map Pattern

Simple, declarative, dependency-free. Good for machines with no side effects in the transition logic itself.

```typescript
const OrderStatus = {
  Draft: 'draft',
  Submitted: 'submitted',
  Paid: 'paid',
  Shipped: 'shipped',
  Delivered: 'delivered',
  Completed: 'completed',
  Cancelled: 'cancelled',
  Returned: 'returned',
  Refunded: 'refunded',
} as const;

type OrderStatus = (typeof OrderStatus)[keyof typeof OrderStatus];

const OrderEvent = {
  OrderPlaced: 'orderPlaced',
  CancellationRequested: 'cancellationRequested',
  PaymentReceived: 'paymentReceived',
  ChangesRequested: 'changesRequested',
  Dispatched: 'dispatched',
  RefundIssued: 'refundIssued',
  DeliveryConfirmed: 'deliveryConfirmed',
  ReturnRequested: 'returnRequested',
  ReturnWindowClosed: 'returnWindowClosed',
  ReturnReceived: 'returnReceived',
} as const;

type OrderEvent = (typeof OrderEvent)[keyof typeof OrderEvent];

const transitions: Record<string, OrderStatus> = {
  [`${OrderStatus.Draft}:${OrderEvent.OrderPlaced}`]: OrderStatus.Submitted,
  [`${OrderStatus.Draft}:${OrderEvent.CancellationRequested}`]: OrderStatus.Cancelled,
  [`${OrderStatus.Submitted}:${OrderEvent.PaymentReceived}`]: OrderStatus.Paid,
  [`${OrderStatus.Submitted}:${OrderEvent.CancellationRequested}`]: OrderStatus.Cancelled,
  [`${OrderStatus.Submitted}:${OrderEvent.ChangesRequested}`]: OrderStatus.Draft,
  [`${OrderStatus.Paid}:${OrderEvent.Dispatched}`]: OrderStatus.Shipped,
  [`${OrderStatus.Paid}:${OrderEvent.RefundIssued}`]: OrderStatus.Refunded,
  [`${OrderStatus.Shipped}:${OrderEvent.DeliveryConfirmed}`]: OrderStatus.Delivered,
  [`${OrderStatus.Shipped}:${OrderEvent.ReturnRequested}`]: OrderStatus.Returned,
  [`${OrderStatus.Delivered}:${OrderEvent.ReturnWindowClosed}`]: OrderStatus.Completed,
  [`${OrderStatus.Delivered}:${OrderEvent.ReturnRequested}`]: OrderStatus.Returned,
  [`${OrderStatus.Returned}:${OrderEvent.ReturnReceived}`]: OrderStatus.Refunded,
};

function transition(current: OrderStatus, event: OrderEvent): OrderStatus {
  const next = transitions[`${current}:${event}`];
  if (!next) {
    throw new Error(`Event ${event} is not handled in ${current} status`);
  }
  return next;
}
```

### Library Implementations

When the machine needs context, guards over context, nested or parallel states, or delayed transitions, implement it with a statechart library. Each library has its own how-to under `libraries/`, covering the machine definition, testing, and a library-specific checklist:

- [libraries/xstate.md](libraries/xstate.md): XState v5

Add a new library as `libraries/<name>.md` with the same three sections, built on the same order lifecycle so the how-tos stay comparable.

## Testing State Machines

### What to Test

| Category | What to Verify |
|----------|---------------|
| **Happy paths** | Each valid transition produces correct next state |
| **Invalid transitions** | Rejected events in wrong states throw/return errors |
| **Guards** | Transitions blocked when guard conditions are false |
| **Actions** | Entry, exit, and transition actions fire correctly |
| **Context** | State context is updated correctly on transitions |
| **Terminal states** | Final states accept no further transitions |
| **Full paths** | End-to-end flows through the entire lifecycle |

### Testing the Transition Map Pattern

```typescript
import { describe, it, expect } from 'vitest';

describe('order state machine', () => {
  describe('valid transitions', () => {
    it.each([
      ['draft', 'orderPlaced', 'submitted'],
      ['draft', 'cancellationRequested', 'cancelled'],
      ['submitted', 'paymentReceived', 'paid'],
      ['submitted', 'cancellationRequested', 'cancelled'],
      ['submitted', 'changesRequested', 'draft'],
      ['paid', 'dispatched', 'shipped'],
      ['paid', 'refundIssued', 'refunded'],
      ['shipped', 'deliveryConfirmed', 'delivered'],
      ['shipped', 'returnRequested', 'returned'],
      ['delivered', 'returnWindowClosed', 'completed'],
      ['delivered', 'returnRequested', 'returned'],
      ['returned', 'returnReceived', 'refunded'],
    ] as const)('%s + %s → %s', (from, event, expected) => {
      expect(transition(from, event)).toBe(expected);
    });
  });

  describe('rejected transitions', () => {
    it.each([
      ['draft', 'paymentReceived'],
      ['draft', 'dispatched'],
      ['submitted', 'dispatched'],
      ['paid', 'cancellationRequested'],
      ['completed', 'cancellationRequested'],
      ['cancelled', 'orderPlaced'],
      ['refunded', 'refundIssued'],
    ] as const)('%s + %s → throws', (from, event) => {
      expect(() => transition(from, event)).toThrow();
    });
  });

  describe('end-to-end paths', () => {
    it('happy path: draft → completed', () => {
      let status: OrderStatus = 'draft';
      for (const event of ['orderPlaced', 'paymentReceived', 'dispatched', 'deliveryConfirmed', 'returnWindowClosed'] as const) {
        status = transition(status, event);
      }
      expect(status).toBe('completed');
    });

    it('return path: draft → refunded', () => {
      let status: OrderStatus = 'draft';
      for (const event of ['orderPlaced', 'paymentReceived', 'dispatched', 'returnRequested', 'returnReceived'] as const) {
        status = transition(status, event);
      }
      expect(status).toBe('refunded');
    });

    it('cancellation from submitted', () => {
      let status: OrderStatus = 'draft';
      status = transition(status, 'orderPlaced');
      status = transition(status, 'cancellationRequested');
      expect(status).toBe('cancelled');
    });
  });

  describe('terminal states', () => {
    const terminalStates: OrderStatus[] = ['completed', 'cancelled', 'refunded'];
    const allEvents = Object.values(OrderEvent);

    for (const state of terminalStates) {
      it(`${state} rejects all events`, () => {
        for (const event of allEvents) {
          expect(() => transition(state, event)).toThrow();
        }
      });
    }
  });
});
```

### Testing Strategies Checklist

1. **Table-driven tests** for transition maps: enumerate all valid/invalid pairs
2. **Guard isolation**: test each guard predicate returns correct boolean independently
3. **Context snapshots**: assert context shape after each transition
4. **Path coverage**: test every reachable path from initial to each final state
5. **Exhaustive invalid transitions**: for every `(state, event)` pair not in the valid set, assert rejection

Library-specific strategies (action spies, delay overrides, model-based testing) live in the library's how-to under `libraries/`.
