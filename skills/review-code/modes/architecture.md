# Mode: `architecture`

Single-pass through one lens: did this change make the codebase's structure better or worse? Not correctness, not security — structure and design quality.

A **deep module** (Ousterhout, *A Philosophy of Software Design*) hides a large implementation behind a small interface. Shallow modules, leaky boundaries, and tight coupling are the friction this mode surfaces.

## Workflow

1. Resolve scope (see SKILL.md → *Shared: Resolve scope*).
2. Read changed files in full, **plus their callers** — architecture lives in the seams; a diff alone hides coupling.
3. Analyze each change against the checklist.
4. Emit findings using the standard output template (see SKILL.md → *Shared: Standard output template*), then a verdict.

## Checklist

- **Module depth** — new modules whose interface is nearly as complex as their implementation; pass-through wrappers
- **Coupling** — new dependencies between modules that shouldn't know about each other; one concept spread thin
- **Abstraction boundaries** — interfaces leaking implementation detail; callers forced to know internals
- **Layering** — direction-of-dependency violations (domain importing infra, UI reaching into persistence)
- **Responsibility placement** — logic bolted onto a convenient caller instead of the owning module
- **Testability at the seam** — can the new behavior be tested at the module boundary?
- **Speculative structure** — abstractions with a single caller and no concrete second use
- **Naming & clarity** — names express intent; control flow followable without tracing every branch
- **Dead weight** — code, exports, parameters left unused

Each finding names the structural problem *and* the cheaper shape — not just "this is coupled".

## Rules (mode-specific)

- Pre-existing problems are out of scope unless the change makes them worse.
- Propose the smaller-interface alternative concretely; flag uncertainty rather than guessing.

Shared rules in SKILL.md apply.
