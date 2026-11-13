# Type narrowing

TypeScript refines a value's type based on control flow. A check on a union narrows the type inside the guarded block.

## Narrowing hierarchy

From best to last-resort:

1. **Discriminated union switch / if.** Compiler narrows automatically.
2. **`in` operator.** `"key" in obj` narrows to variants containing that key.
3. **`typeof` / `instanceof`.** For primitives and class instances.
4. **User-defined type guard.** When the above aren't enough.
5. **`as` cast.** Only after validation.

```ts
function area(s: Shape): number {
  if ("radius" in s) return Math.PI * s.radius ** 2; // narrowed to circle
  return s.width * s.height; // narrowed to rect
}
```

## Discriminated unions

If a bug forces the question "wait, can this combination actually happen?", the type is too loose. Model variants with a literal discriminant: every variant shares the field name and each variant's value is unique, so impossible combos can't be represented.

```ts
// Don't. Boolean + optionals lets contradictory states exist.
type DiffState = { loading: boolean; diff?: GitDiff; error?: string };

// Do. Only valid states exist.
type DiffState =
  | { kind: "loading" }
  | { kind: "ready"; diff: GitDiff }
  | { kind: "error"; error: string };
```

Pick one discriminant name (`kind`, `type`, `tag`) and stick to it.

```ts
type Shape =
  | { kind: "circle"; radius: number }
  | { kind: "rect"; width: number; height: number };

function area(shape: Shape): number {
  switch (shape.kind) {
    case "circle":
      return Math.PI * shape.radius ** 2; // Circle
    case "rect":
      return shape.width * shape.height; // Rect
  }
}
```

## Exhaustiveness

In default arms, assign the discriminant to a `never`-typed local. The compiler errors if a new variant is added without handling.

```ts
// Value-returning switch
function area(s: Shape): number {
  switch (s.kind) {
    case "circle":
      return Math.PI * s.radius ** 2;
    case "rect":
      return s.width * s.height;
    default: {
      const _exhaustive: never = s;
      return _exhaustive;
    }
  }
}

// Void switch
function handle(s: Shape): void {
  switch (s.kind) {
    case "circle":
      drawCircle(s);
      break;
    case "rect":
      drawRect(s);
      break;
    default: {
      const _exhaustive: never = s;
      void _exhaustive;
    }
  }
}
```

Return-style in value-returning switches; void-style in statement switches.

## Built-in narrowing

### `in` operator

```ts
interface Fish { swim: () => void }
interface Bird { fly: () => void }

function move(animal: Fish | Bird) {
  if ("swim" in animal) {
    animal.swim(); // Fish
  } else {
    animal.fly(); // Bird
  }
}
```

### `typeof`

```ts
function processValue(value: string | number) {
  if (typeof value === "string") return value.toUpperCase(); // string
  return value.toFixed(2); // number
}
```

### `instanceof`

```ts
function logError(error: Error | string) {
  if (error instanceof Error) {
    console.log(error.stack); // Error
  } else {
    console.log(error); // string
  }
}
```

### Truthiness

```ts
function printName(name: string | null | undefined) {
  if (name) console.log(name.toUpperCase()); // string
}
```

Truthiness on a compound condition does not narrow either operand:

```ts
function example(value: { a?: string; b?: number }) {
  if (value.a || value.b) {
    // neither a nor b is guaranteed to exist
  }
  if (value.a !== undefined) {
    // value.a is string
  }
}
```

### Equality

```ts
function example(x: string | number, y: string | boolean) {
  if (x === y) {
    // both are string (only common type)
    x.toUpperCase();
    y.toUpperCase();
  }
}
```

## Type guards

A guard must actually verify the claim. A lying guard is worse than `as` because the bug hides behind a name that says it's safe.

```ts
function isCircle(s: Shape): s is Shape & { kind: "circle" } {
  return s.kind === "circle";
}
```

Prefer discriminant narrowing when possible. The guard adds a layer the reader has to follow.

A guard without the `x is T` return annotation returns a plain boolean and narrows nothing:

```ts
// Doesn't narrow
function isFish(pet: Fish | Bird) {
  return "swim" in pet;
}

// Narrows
function isFish(pet: Fish | Bird): pet is Fish {
  return "swim" in pet;
}
```

### Generic guards

```ts
function isNotNull<T>(value: T | null | undefined): value is T {
  return value !== null && value !== undefined;
}

const values = [1, null, 2, undefined, 3];
const filtered = values.filter(isNotNull); // number[]
```

### Array filtering

```ts
type Item = { type: "a"; value: string } | { type: "b"; count: number };

const typeAItems = items.filter(
  (item): item is { type: "a"; value: string } => item.type === "a"
); // { type: "a"; value: string }[]
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

### Guards with branded types

Combine a predicate with a brand so the validated value carries proof:

```ts
type ValidEmail = string & { __brand: "ValidEmail" };

function isValidEmail(email: string): email is ValidEmail {
  return email.includes("@") && email.includes(".");
}

function sendEmail(email: ValidEmail) {}

function handleSubmit(email: string) {
  if (!isValidEmail(email)) throw new Error("Invalid email");
  sendEmail(email); // ValidEmail
}
```

## Assertion functions

Throw on invalid input; the caller's value is narrowed after the call.

```ts
function assertIsString(value: unknown): asserts value is string {
  if (typeof value !== "string") {
    throw new Error(`Expected string, got ${typeof value}`);
  }
}

function processInput(input: unknown) {
  assertIsString(input);
  input.toUpperCase(); // string
}
```

Must be a `function` declaration, not an arrow function assigned to a `const`:

```ts
// Error: Assertions require every name in the call target to be
// declared with an explicit type annotation.
const assertString = (value: unknown): asserts value is string => {
  if (typeof value !== "string") throw new Error("Not a string");
};

// Correct
function assertString(value: unknown): asserts value is string {
  if (typeof value !== "string") throw new Error("Not a string");
}
```

## Control flow limits

Narrowing applies only to inline checks. It does not follow a boolean stored in a variable:

```ts
function example(value: string | number) {
  const isStr = isString(value);
  if (isStr) {
    // value is still string | number
  }
  if (isString(value)) {
    // value is string
  }
}
```

Narrowing does not persist into callbacks:

```ts
function example(value: string | null) {
  if (value !== null) {
    setTimeout(() => {
      // value is string | null again
    }, 0);
  }
}
```

## Choosing a technique

| Technique | Use case |
|-----------|----------|
| Discriminated union | Related variants sharing a literal discriminant |
| `in` | Property existence |
| `typeof` | Primitives |
| `instanceof` | Class instances |
| Type predicate | Custom narrowing the above can't express |
| Assertion function | Validate and throw early |
