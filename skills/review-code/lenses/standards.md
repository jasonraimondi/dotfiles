# Lens: `standards`

Does this code look like the rest of this repo, and does it carry avoidable smells?

## Inputs

The diff. Read a changed file in full only to confirm a specific suspicion.

Find the repo's documented standards first: `CODING_STANDARDS.md`, `CONTRIBUTING.md`, `CLAUDE.md`, `AGENTS.md`, `.editorconfig`, or whatever the repo actually keeps. Find its **design records** too — ADRs, `GLOSSARY.md`, the docs beside the changed modules — and read the ones covering the changed area. Those are the authority. On top of them, the **smell baseline** below applies even to a repo that documents nothing.

Two rules bind the baseline:

- **The repo overrides.** Where a documented standard endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation.

Skip anything tooling already enforces — a linter finding is not a review finding.

## Records and comments

- **Reversed decision** — the change contradicts a design record and leaves the record as it was. Quote the record's line and the code that now disagrees. The finding is the mismatch; whether the decision should change is a question for the author.
- **Deleted rationale** — a *why* comment removed while the reason it gave still holds.
- **Stale comment** — a comment or doc, in or beside the changed code, that the change makes false.

## Smell baseline

Fowler, *Refactoring* ch.3. Each reads *what it is* → *how to fix*; match it against the diff.

- **Mysterious Name**: a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps**: the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession**: a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches**: the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery**: one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change**: one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

## Output

Per finding: whether it's a **documented-standard breach** (cite the standard's file and rule), a **reversed decision** (cite the record's file and line), or a **baseline smell** (name the smell). A documented breach or a reversed decision can be blocking; a smell is a judgement call.

## Rules

Report on changed code. Pre-existing style is out of scope unless the change spreads it further.
