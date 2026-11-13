# Diagnosing TypeScript errors

## Read errors bottom-up

TypeScript prints errors top-down; the cause is usually the last line.

```
Type '{ name: string; }' is not assignable to type 'User'.
  Types of property 'email' are incompatible.
    Type 'undefined' is not assignable to type 'string'.
                                                ^^^^^^ the actual issue
```

Long errors follow the same rule: one core problem, buried at the end.

```
Type '{ fullName: string; id: string; firstName: string; lastName: string; age: number; }'
is not assignable to type
'{ fullName: string; id: string; firstName: string; lastName: string; age: number; agePlus10: number }'.

Property 'agePlus10' is missing in type '{ ... }'
but required in type '{ fullName: string; agePlus10: number; }'.
         ^^^^^^^^^ the actual issue
```

## Inspect types

- Hover to see the inferred type of any expression.
- Go-to-definition on the symbol to see what is expected; `(+N overload)` in a tooltip means there are more signatures, and the first matching overload wins.
- Library definitions live in `node_modules/@types/<lib>` or `node_modules/<lib>/dist/*.d.ts`.

```typescript
// lib.dom.d.ts
interface Document {
  querySelector<K extends keyof HTMLElementTagNameMap>(selectors: K): HTMLElementTagNameMap[K] | null;
  querySelector(selectors: string): Element | null;
}
```

## Break the problem down

Split complex type expressions into named steps and hover each.

```typescript
type Result = SomeComplexType<Input>[keyof Input][number];

type Step1 = SomeComplexType<Input>;
type Step2 = Step1[keyof Input];
type Step3 = Step2[number];
```

Split call chains the same way.

```typescript
const step1 = complexFunction();
const step2 = step1.map(transform);
const step3 = step2.filter(predicate);
```

Name both sides of a failing comparison to diff them.

```typescript
type Actual = typeof problematicValue;
type Expected = ExpectedType;
```

Add explicit annotations to pin where the mismatch starts.

```typescript
const data: ExpectedDataType = getData();       // errors if getData is wrong
const result: ExpectedResultType = data.process(); // errors if process is wrong
```

Use `@ts-expect-error` to confirm a hypothesis: if the directive is reported as unused, the code is actually valid.

```typescript
// @ts-expect-error string is not assignable to number
const x: number = "hello";
```

## Common error patterns

### "Type 'X' is not assignable to type 'Y'"

Check for missing properties, incompatible property types, or a literal vs widened mismatch.

```typescript
const status = "active"; // string (widened)
function setStatus(s: "active" | "inactive") {}
setStatus(status); // Error

const status = "active" as const; // "active"
setStatus(status); // OK
```

### "Property 'X' does not exist on type 'Y'"

The type lacks the property; narrow first.

```typescript
function process(data: unknown) {
  data.name; // Error

  if (typeof data === "object" && data !== null && "name" in data) {
    data.name; // OK
  }
}
```

### "Type 'X' cannot be used to index type 'Y'"

Constrain the key.

```typescript
function getValue<T>(obj: T, key: string) {
  return obj[key]; // Error
}

function getValue<T, K extends keyof T>(obj: T, key: K) {
  return obj[key]; // OK
}
```

### "Argument of type 'X' is not assignable to parameter of type 'Y'"

Usually a narrower signature than the argument.

```typescript
const items = ["a", "b", "c"] as const;
items.includes(someString); // Error: string not assignable to "a" | "b" | "c"

(items as readonly string[]).includes(someString);
```

### "Type 'X' is not generic"

Type arguments passed to a non-generic type.

```typescript
type NotGeneric = string;
type Attempt = NotGeneric<number>; // Error

type IsGeneric<T> = T;
type Works = IsGeneric<number>; // OK
```

### "'T' does not satisfy constraint ..."

Add the constraint the utility type requires.

```typescript
function process<T>(items: Parameters<T>) {} // Error

function process<T extends (...args: any) => any>(items: Parameters<T>) {}
```

## When library types are wrong

Assert when you know better than the declaration.

```typescript
const element = document.getElementById("root") as HTMLDivElement;
```

Merge declarations to extend an incomplete type.

```typescript
declare module "some-library" {
  interface SomeType {
    missingProperty: string;
  }
}
```

Otherwise report upstream with a reproduction.

## Prevention

- `"strict": true` in `compilerOptions`.
- `unknown` instead of `any`, then narrow with guards.
- Constrain generics (`<T extends object>`) instead of defaulting to `any`.
- Consider edge inputs (empty string, empty array, `string | string[]`).
- Match the IDE's TypeScript version to the project's; enable inlay hints; use Quick Fix.

## Type tests

Add a type test when the project has a type-test harness and the behaviour is reusable, subtle, or a regression needs a compile-time guard.

```typescript
type AssertEqual<T, U> = [T] extends [U]
  ? [U] extends [T]
    ? true
    : false
  : false;

type Test1 = AssertEqual<string, string>; // true
type Test2 = AssertEqual<string, number>; // false
type Test3 = AssertEqual<string | number, string>; // false

type ExpectError<T extends never> = T;

type ShouldError = ExpectError<AssertEqual<string, number>>;
```
