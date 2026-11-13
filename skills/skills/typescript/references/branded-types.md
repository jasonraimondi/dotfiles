# Branded types

Brand primitives so values with the same underlying type but different meanings can't be mixed up. Validate once at creation; downstream code trusts the type.

```ts
type AgentId = string & { readonly __brand: "AgentId" };

function parseAgentId(input: string): AgentId {
  if (!isUUID(input)) throw new Error(`Invalid agent id: ${input}`);
  return input as AgentId;
}

function focusAgent(id: AgentId): void {
  /* input is trusted */
}
```

Match the `readonly __brand: 'X'` shape; don't invent a new convention. The `as` cast belongs only inside the parse/validate function.

## Why

TypeScript is structural, so aliases of the same primitive are interchangeable:

```ts
type UserId = string;
type PostId = string;

function getUser(id: UserId): User { /* ... */ }

const postId: PostId = "post-456";
getUser(postId); // no error
```

With a brand, the phantom property makes the types nominally distinct:

```ts
type UserId = string & { readonly __brand: "UserId" };
type PostId = string & { readonly __brand: "PostId" };

getUser(userId); // OK
getUser(postId); // Error: 'PostId' is not assignable to 'UserId'
```

Use for entity IDs (`UserId`, `OrderId`), validated strings (`ValidEmail`, `Url`), validated numbers (`Age`, `Price`), and security-sensitive values (`HashedPassword`, `ApiKey`).

## Creation patterns

Three ways to move from a raw primitive into the brand. All validate at the boundary and cast once.

Throwing factory (shown above): returns the brand or throws.

Nullable parser, when the caller handles failure:

```ts
function parseUserId(id: string): UserId | null {
  return id.startsWith("user_") ? (id as UserId) : null;
}
```

Type predicate, for narrowing in an `if`:

```ts
const isValidEmail = (email: string): email is ValidEmail =>
  email.includes("@") && email.includes(".");

function processEmail(email: string): void {
  if (!isValidEmail(email)) throw new Error("Invalid email");
  sendEmail(email); // email: ValidEmail
}
```

Assertion function, for narrowing without a branch. Must be a `function` declaration; arrow functions fail with "Assertions require every name in the call target to be declared with an explicit type annotation":

```ts
function assertValidEmail(email: string): asserts email is ValidEmail {
  if (!email.includes("@") || !email.includes(".")) throw new Error("Invalid email format");
}

async function createUser(data: { email: string }) {
  assertValidEmail(data.email);
  return saveUser({ email: data.email }); // data.email: ValidEmail
}
```

| | Type predicate | Assertion function |
|---|---|---|
| Returns | `boolean` | `void`, throws on failure |
| Usage | in `if` | standalone call |
| Failure | caller handles | function throws |
| Syntax | arrow or `function` | `function` only |

## End to end

```ts
type ValidEmail = string & { readonly __brand: "ValidEmail" };
type ValidPassword = string & { readonly __brand: "ValidPassword" };
type UserId = string & { readonly __brand: "UserId" };

function assertValidEmail(email: string): asserts email is ValidEmail {
  if (!email.includes("@") || email.length < 5) throw new Error("Invalid email format");
}

function assertValidPassword(password: string): asserts password is ValidPassword {
  if (password.length < 8) throw new Error("Password must be at least 8 characters");
}

async function createUser(data: { email: ValidEmail; password: ValidPassword }): Promise<{ id: UserId }> {
  return { id: crypto.randomUUID() as UserId };
}

async function handleRegistration(input: { email: string; password: string }) {
  assertValidEmail(input.email);
  assertValidPassword(input.password);
  return createUser({ email: input.email, password: input.password });
}
```

## Unwrapping

A branded value is still its primitive at runtime and structurally; pass it anywhere the base type is accepted with no conversion:

```ts
const id: UserId = parseUserId(raw);
id.toUpperCase();          // string methods work
const s: string = id;      // widening is free
```

Only the reverse direction (`string` to `UserId`) requires going through a creation function.

## Casting outside the boundary

`raw as UserId` anywhere except the parse function silently defeats the brand:

```ts
processUser(request.body.id as UserId); // unvalidated

assertUserId(request.body.id);
processUser(request.body.id);           // validated
```

## Unique symbol brand

If a `__brand` string key could collide with a real property, brand with a `unique symbol` instead. Only reach for this when the collision is real; otherwise keep the standard shape.

```ts
declare const brand: unique symbol;
type Brand<T, TBrand> = T & { readonly [brand]: TBrand };

type UserId = Brand<string, "UserId">;
```
