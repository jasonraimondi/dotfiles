# Utility types and derived types

## Derive, don't redeclare

When a `.proto`, OpenAPI spec, GraphQL schema, database migration, library, or existing function already defines a shape, derive from it. Reach for `Pick`, `Omit`, `Parameters`, `ReturnType`, `Awaited`, `typeof` before writing a new interface. A duplicated shape drifts when the source changes.

```ts
// Don't. Duplicate shape, drifts when the schema changes.
type CheckSummary = {
  totalCount: number;
  checks: { name: string; status: string }[];
};
function renderChecks(s: CheckSummary) {}

// Do. Derive from the generated schema type.
import type { ChecksMessage } from "<generated module>";
function renderChecks(s: Pick<ChecksMessage, "totalCount" | "checks">) {}
```

Wrapping a library function that does not export its types:

```ts
import { fetchUser } from "external-lib";

type FetchUserReturn = Awaited<ReturnType<typeof fetchUser>>;

export const fetchUserWithFullName = async (
  ...args: Parameters<typeof fetchUser>
): Promise<FetchUserReturn & { fullName: string }> => {
  const user = await fetchUser(...args);
  return { ...user, fullName: `${user.firstName} ${user.lastName}` };
};
```

Generalized as a reusable helper:

```ts
type WrapFunction<TFunc extends (...args: any) => any, TAdditional = {}> = (
  ...args: Parameters<TFunc>
) => Promise<Awaited<ReturnType<TFunc>> & TAdditional>;

const fetchUserWithMeta: WrapFunction<typeof fetchUser, { meta: { fetchedAt: Date } }> =
  async (...args) => ({ ...(await fetchUser(...args)), meta: { fetchedAt: new Date() } });
```

## Built-in utility types

| Utility | Use |
|---------|-----|
| `Parameters<T>` | Wrapping functions, function variants |
| `ReturnType<T>` | Return types not explicitly exported |
| `Awaited<T>` | Unwrap Promise (including nested) |
| `Record<K, V>` | Object types with known keys |
| `Partial<T>` | Update/patch inputs |
| `Required<T>` | Fully-resolved config |
| `Omit<T, K>` | Drop sensitive or internal fields |
| `Pick<T, K>` | Focused subset |
| `Exclude<T, U>` | Filter a union |
| `Extract<T, U>` | Select from a union |
| `NonNullable<T>` | Strip `null | undefined` |

`Parameters`, `ReturnType`, `Awaited`:

```ts
function fetchUser(id: string, opts?: { timeout?: number }): Promise<User> {}

type FetchUserParams = Parameters<typeof fetchUser>;
// [id: string, opts?: { timeout?: number } | undefined]

const fetchUserWithLogging = async (...args: Parameters<typeof fetchUser>) => {
  console.log("Fetching user:", args[0]);
  return fetchUser(...args);
};

function createUser(name: string, email: string) {
  return { id: crypto.randomUUID(), name, email, createdAt: new Date() };
}
type User = ReturnType<typeof createUser>;
// { id: string; name: string; email: string; createdAt: Date }

type Unwrapped = Awaited<Promise<Promise<number>>>; // number
type FetchUserResult = Awaited<ReturnType<typeof fetchUser>>; // User, not Promise<User>
```

`ReturnType` on an async function yields the `Promise`; wrap in `Awaited` to unwrap. `Parameters<myFunc>` is an error because `myFunc` is a value; use `Parameters<typeof myFunc>`.

`Record`:

```ts
type Role = "admin" | "user" | "guest";
const rolePermissions: Record<Role, string[]> = {
  admin: ["read", "write", "delete"],
  user: ["read", "write"],
  guest: ["read"],
};

function createLookup<K extends string, V>(keys: K[], getValue: (key: K) => V): Record<K, V> {
  const result = {} as Record<K, V>;
  for (const key of keys) result[key] = getValue(key);
  return result;
}
```

`Partial`, `Required`, `Omit`, `Pick`:

```ts
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
}

type UpdateUserInput = Partial<User>; // all optional
function updateUser(id: string, updates: Partial<User>): User {}
updateUser("123", { name: "New Name" });

interface Config { host?: string; port?: number; debug?: boolean }
type RequiredConfig = Required<Config>; // { host: string; port: number; debug: boolean }

type PublicUser = Omit<User, "password">;
type CreateUserInput = Omit<User, "id">;
type UserCredentials = Pick<User, "email" | "password">;
```

`Exclude`, `Extract`, `NonNullable`:

```ts
type AllColors = "red" | "green" | "blue" | "yellow";
type PrimaryColors = Extract<AllColors, "red" | "blue">; // "red" | "blue"
type NonPrimaryColors = Exclude<AllColors, "red" | "blue">; // "green" | "yellow"

type DefiniteString = NonNullable<string | null | undefined>; // string
```

## `as const` and `typeof`

`as const` makes a value deeply readonly and infers literal types instead of widened ones; arrays become readonly tuples. `typeof` pulls the runtime value into the type world. Together they give one source of truth for runtime and compile time (config objects, enum alternatives, routes, API mappings, event names).

```ts
const config = { GROUP: "group", ANNOUNCEMENT: "announcement" };
// { GROUP: string; ANNOUNCEMENT: string }

const config = { GROUP: "group", ANNOUNCEMENT: "announcement" } as const;
// { readonly GROUP: "group"; readonly ANNOUNCEMENT: "announcement" }

const routes = ["home", "about", "contact"] as const;
// readonly ["home", "about", "contact"]  (without as const: string[])

config.GROUP = "x"; // Error: read-only property
```

Keys, values, and subsets:

```ts
const programModeEnumMap = {
  GROUP: "group",
  ANNOUNCEMENT: "announcement",
  ONE_ON_ONE: "1on1",
  SELF_DIRECTED: "selfDirected",
} as const;

type ProgramMap = typeof programModeEnumMap;

type BackendProgram = keyof typeof programModeEnumMap;
// "GROUP" | "ANNOUNCEMENT" | "ONE_ON_ONE" | "SELF_DIRECTED"

// Obj[keyof Obj] is Object.values() for the type world
type FrontendProgram = ProgramMap[keyof ProgramMap];
// "group" | "announcement" | "1on1" | "selfDirected"

type IndividualProgram = ProgramMap["ONE_ON_ONE" | "SELF_DIRECTED"];
// "1on1" | "selfDirected"
```

Without `as const`, `typeof colors[keyof typeof colors]` widens to `string`.

```ts
const HTTP_METHODS = { GET: "GET", POST: "POST", PUT: "PUT", DELETE: "DELETE", PATCH: "PATCH" } as const;

type HttpMethod = typeof HTTP_METHODS[keyof typeof HTTP_METHODS];
type SafeMethod = typeof HTTP_METHODS["GET"]; // "GET"

function makeRequest(method: HttpMethod, url: string): void {}
makeRequest(HTTP_METHODS.GET, "/api/users"); // OK
makeRequest("INVALID", "/api/users"); // Error
```

## `[number]` index access

Indexing an array type with `number` yields the union of all element types, for any length. Requires `as const` on literal arrays or elements widen to `string`.

```ts
const roles = ["user", "admin", "anonymous"] as const;

type FirstRole = typeof roles[0]; // "user"
type AnyRole = typeof roles[number]; // "user" | "admin" | "anonymous"

const tuple = ["hello", 42, true] as const;
type TupleElements = typeof tuple[number]; // "hello" | 42 | true

const array: string[] = ["a", "b", "c"];
type ArrayElement = typeof array[number]; // string

type ParamsUnion = Parameters<(a: string, b: number, c: boolean) => void>[number];
// string | number | boolean
```

Nested with `keyof`, e.g. role-based access control:

```ts
const userAccessModel = {
  user: ["update-self", "view"],
  admin: ["create", "update-self", "update-any", "delete", "view"],
  anonymous: ["view"],
} as const;

type Role = keyof typeof userAccessModel;
type Action = typeof userAccessModel[Role][number];
// "update-self" | "view" | "create" | "update-any" | "delete"

const canUserAccess = (role: Role, action: Action): boolean =>
  // .includes on a readonly tuple rejects the wider Action union; widen the array
  (userAccessModel[role] as ReadonlyArray<Action>).includes(action);

canUserAccess("admin", "delete"); // OK
canUserAccess("admin", "invalid"); // Error
```

Equivalent via `infer`:

```ts
type ExtractArrayElements<T> = T extends readonly (infer U)[] ? U : never;
type Permission = ExtractArrayElements<typeof permissions>;
```
