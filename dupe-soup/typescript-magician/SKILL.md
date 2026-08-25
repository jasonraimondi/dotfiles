---
name: typescript-magician
description: Designs complex generic types, refactors `any` types to strict alternatives, creates type guards and utility types, and resolves TypeScript compiler errors. Use when the user asks about TypeScript (TS) types, generics, type inference, type guards, removing `any` types, strict typing, type errors, `infer`, `extends`, conditional types, mapped types, template literal types, branded/opaque types, or utility types like `Partial`, `Record`, `ReturnType`, and `Awaited`.
disable-model-invocation: true
---

## Instructions

When invoked:
1. Inspect the project’s `package.json` scripts, workspace layout, and relevant `tsconfig*.json` files. Select the narrowest existing typecheck command for the affected package or project; ask when the intended command is unclear.
2. Run that command before changing code and capture the relevant diagnostics.
3. Identify the root cause, then read only the relevant rule files below.
4. Make the smallest sound type change. Replace accidental or unsafe `any` with a precise type, generic, or `unknown` plus narrowing. Keep an intentional `any` at a documented interop boundary when it is the appropriate contract.
5. Rerun the same typecheck command and any focused existing test or type-test command affected by the change.

## Communication and type tests

- For a local compiler-error repair, explain the cause and fix concisely.
- Explain the underlying type behavior, compare alternatives, and show before/after type representations when requested or when changing a public or reusable type API.
- Add or update type tests when the project has a type-test harness, the behavior is reusable or subtle, or a regression needs a compile-time guard.

## Quick Examples

### Eliminating `any` with generics

**Before**
```ts
function getProperty(obj: any, key: string): any {
  return obj[key];
}
```

**After**
```ts
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
// getProperty({ name: "Alice" }, "name") → inferred as string ✓
```

### Narrowing an unknown API response

**Before**
```ts
async function fetchUser(): Promise<any> {
  const res = await fetch("/api/user");
  return res.json();
}
```

**After**
```ts
interface User { id: number; name: string }

function isUser(value: unknown): value is User {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value &&
    "name" in value
  );
}

async function fetchUser(): Promise<User> {
  const res = await fetch("/api/user");
  const data: unknown = await res.json();
  if (!isUser(data)) throw new Error("Invalid user shape");
  return data;
}
```

## Reference

Read individual rule files for detailed explanations and code examples:

### Core Patterns
- [rules/as-const-typeof.md](rules/as-const-typeof.md) - Deriving types from runtime values using `as const` and `typeof`
- [rules/array-index-access.md](rules/array-index-access.md) - Accessing array element types using `[number]` indexing
- [rules/utility-types.md](rules/utility-types.md) - Built-in utility types: Parameters, ReturnType, Awaited, Omit, Partial, Record

### Advanced Generics
- [rules/generics-basics.md](rules/generics-basics.md) - Fundamentals of generic types, constraints, and inference
- [rules/builder-pattern.md](rules/builder-pattern.md) - Type-safe builder pattern with chainable methods
- [rules/deep-inference.md](rules/deep-inference.md) - Achieving deep type inference with F.Narrow and const type parameters

### Type-Level Programming
- [rules/conditional-types.md](rules/conditional-types.md) - Conditional types for type-level if/else logic
- [rules/infer-keyword.md](rules/infer-keyword.md) - Using `infer` to extract types within conditional types
- [rules/template-literal-types.md](rules/template-literal-types.md) - String manipulation at the type level
- [rules/mapped-types.md](rules/mapped-types.md) - Creating new types by transforming existing type properties

### Type Safety Patterns
- [rules/opaque-types.md](rules/opaque-types.md) - Brand types and opaque types for type-safe identifiers
- [rules/type-narrowing.md](rules/type-narrowing.md) - Narrowing types through control flow analysis
- [rules/function-overloads.md](rules/function-overloads.md) - Using function overloads for complex function signatures

### Debugging
- [rules/error-diagnosis.md](rules/error-diagnosis.md) - Strategies for diagnosing and understanding TypeScript type errors
