# Design Principles

The ideas behind the rules in `SKILL.md`. Read when a decision needs more than the rule: whether to nest, whether to split into regions, how to argue a machine is complete, or which implementation shape fits.

## State is compressed history

A state stands for the part of the past that still matters to the next reaction. A keyboard is "shifted" or "default"; which keys came before is irrelevant. When the reaction to an event depends on flags and the conditionals that test them, those flags are states that have not been named yet. Name them, and the conditionals become transitions (Samek).

A state is a finite, qualitative mode the entity is in: `Paid`, `Shipped`. Context is the quantitative or unbounded data that changes within a mode: item count, tracking number. A boolean in context that decides which events are handled is a state in disguise (Stately).

## The state × event grid

A transition reads GIVEN state, WHEN event, THEN next state, which is also the shape of a Gherkin scenario and of an Arrange/Act/Assert test. A machine with S states and E events has S × E cells, and every cell needs a decision: a transition, an explicit ignore, or a rejection, sometimes with an action. A coin dropped into an unlocked turnstile is refunded; a push on a locked one sounds an alarm. The cells off the happy path are where the bugs live, and the grid makes the missing ones visible. The tests are the grid read back (Martin, *Pickled State*).

## Hierarchy is programming by difference

Flat machines explode: every state that shares a transition repeats it. Nesting fixes this. A substate inherits the transitions of its superstate and defines only its differences. An event is offered to the innermost state first and passed outward until some state handles it. Samek calls this behavioral inheritance and applies Liskov substitution to it: a substate must stay consistent with what its superstate promises, so a reader of the outer transition is never surprised inside (Harel, Samek).

Entry and exit actions are guaranteed initialization and cleanup, like constructors and destructors. On entry they run outermost first; on exit, innermost first. Setup and teardown belong there rather than on individual transitions, so every way in and out of the state runs them.

## Orthogonal regions replace product states

When two concerns vary independently, say a connection's auth status and its transport status, a flat machine needs one state per combination. Statecharts put each concern in its own parallel region, and the regions communicate by broadcast events rather than shared flags. Reach for regions when states start being named with "And" (Harel).

## Init, Next, and invariants

Any machine is a set of state variables, an initial predicate, and a next-state relation. That gives three checks a design should pass (Lamport):

- An **invariant** is a predicate true in every reachable state. Prove it inductively: it holds initially, and every transition preserves it. "A shipped order has a tracking number" is an invariant; the design is wrong if any transition into `Shipped` can leave it unset.
- The machine is **deterministic** when, for each state and event, at most one transition is enabled. Guards on the same event from the same state must be mutually exclusive.
- A finite run either **terminates** in a final state or **deadlocks** in one that is not. Every non-final state needs a transition out.

## Run to completion

Processing one event finishes, actions included, before the next event is taken, so the machine is never observed mid-transition. Work that takes time or can fail is therefore a state of its own (`Submitting`, not a slow action on the `orderPlaced` transition), with its completion, failure, and timeout as events (Samek, Stately).

## Choosing an implementation

Keep the semantic model (states, events, transitions, actions) as plain data, independent of how it is authored or rendered (Fowler). Martin's state machine compiler generates code from exactly such a table; the transition map in `SKILL.md` is the same idea without the generator.

- **Transition table**: the default. Flat machine, few actions, no per-state behaviour.
- **State pattern**, one class per state: when behaviour differs per state and states are many or change often. Overkill for a handful of stable states (Gamma et al.).
- **Reducer or statechart library**: when the design uses context, guards, hierarchy, regions, or delays. A plain reducer carries the first three; regions and delays want a library. See `libraries/`.
