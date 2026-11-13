---
name: typescript
description: TypeScript type discipline and type-level design. Use when editing any .ts/.tsx file, modeling domain types, removing `any` or `as`, writing type guards, designing generics, conditional/mapped/template-literal types, or fixing tsc errors.
---

# TypeScript

| Rule | Summary |
|------|---------|
| Discriminated unions | Model variants with a `kind` literal discriminant so impossible states can't be represented. No optional-field bags. |
| Branded types | Brand primitives with `& { readonly __brand: "X" }` so they can't be mixed up. Validate once at creation. |
| Constructive modeling | Build the shape so the illegal value can't be constructed. `[T, ...T[]]` for non-empty, `[T, T][]` for even length, `start` plus `duration` for a range. Not a runtime guard, not a wish for refinement types. |
| Simplest total type | Keep `T[]` while every operation on it stays total. Strengthen to `NonEmpty<T>` only where the loose type forces `!`, a cast, or a "should never happen" throw. |
| `unknown` over `any` | External data is `unknown`. `any` disables type checking everywhere it touches. |
| No `as` casts | Every `as` is a runtime crash waiting. Cast only after validation. |
| Narrowing hierarchy | Discriminant switch > `in` operator > `typeof`/`instanceof` > user-defined type guard > `as`. |
| Type guards | Must verify the claim. A lying guard is worse than `as` because the bug hides behind a name that says it's safe. Name them `isX` or `hasX`. |
| Exhaustiveness | Inline `const _exhaustive: never = x;` in default arms so the compiler errors when a new variant is added. |
| `satisfies` over `as` | Validates the value without widening literal types. |
| Boundary validation | Parse once where data crosses in, into a named domain type; trust types inside. `Record<string, unknown>` (however spelled) stops at that parse. |
| Schema-derived types | Reach for `Pick`/`Omit`/`Parameters`/`ReturnType`/`Awaited`/`typeof` before declaring a new interface. |
| Object args | Pass objects, not positional, so argument order is self-documenting. Skip on hot paths (per-frame render, tokenizers, parsers). |

## When tsc is red or a public or reusable type changes

1. Select the narrowest existing typecheck command for the affected package from `package.json` scripts and `tsconfig*.json`; ask when it is unclear.
2. Run it before changing code and capture the diagnostics.
3. Find the root cause, then load only the matching reference below.
4. Make the smallest sound type change. Replace accidental `any` with a precise type, a generic, or `unknown` plus narrowing; keep an intentional `any` at a documented interop boundary.
5. Rerun the same command and any affected type-test or focused test. Add a type test when the project has a harness and the behaviour is reusable, subtle, or guards a regression.

## Reference

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Modeling | `references/modeling.md` | Constructive modeling, total types, `unknown`, `as`, `satisfies`, boundaries, object args |
| Narrowing | `references/narrowing.md` | Discriminated unions, type guards, exhaustiveness, control-flow narrowing |
| Branded types | `references/branded-types.md` | Nominal ids, opaque primitives |
| Utility types | `references/utility-types.md` | Deriving from schemas, `Pick`/`Omit`/`ReturnType`/`Awaited`, `as const`, `typeof`, `[number]` |
| Generics | `references/generics.md` | Type parameters, constraints, inference, const type parameters |
| Conditional types | `references/conditional-types.md` | Type-level branching, distribution, `infer` |
| Mapped types | `references/mapped-types.md` | Transforming or remapping keys, modifiers |
| Template literal types | `references/template-literal-types.md` | String patterns at the type level, key transformation, route params |
| Builder pattern | `references/builder-pattern.md` | Chainable APIs whose type accumulates per call |
| Function overloads | `references/function-overloads.md` | Multiple signatures for one function |
| Error diagnosis | `references/error-diagnosis.md` | Reading tsc errors, type tests |
