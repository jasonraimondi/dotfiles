# Handoff template

The grill's final artifact: everything needed to implement without re-deriving the thinking, and nothing more. Produce it only when every load-bearing decision is resolved. Do not write implementation until the user approves moving past the grill.

To also compact the wider conversation into a portable doc, the `handoff` skill composes with this.

---

# Implementation handoff: <topic>

## Acceptance criteria
- <observable, checkable condition of done>

## Approach
<the architectural shape in a few sentences — how the pieces fit the existing system>

## Files & patterns
- `<path>` — <its role; the existing pattern to follow>

## Interfaces
<method / type skeletons — signatures and responsibilities, not bodies>

## Constraints & non-goals
- Constraint: <what must hold>
- Non-goal: <what is explicitly out of scope>

## Tasks (ordered)
1. <task> → verify: <check>

## Tests required
- <case to cover, especially edge and failure cases>

## Still needs a human
- <decision deferred to the user, and why>
