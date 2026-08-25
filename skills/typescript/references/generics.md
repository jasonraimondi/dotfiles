# Generics

Generics preserve type information through a function or type instead of erasing it with `any`. Use them when the output type depends on the input type, when one parameter's type depends on another, or when a component must work across types without losing safety.

## Eliminating `any` with generics

Before:

```ts
function getProperty(obj: any, key: string): any {
  return obj[key];
}
```

After:

```ts
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

const user = { name: "Alice", age: 30 };
getProperty(user, "name"); // string
getProperty(user, "age"); // number
getProperty(user, "email"); // Error: "email" not in keyof
```

## Basic generic functions

```ts
function identity<T>(value: T): T {
  return value;
}

const num = identity(42); // number (inferred)
const str = identity("hello"); // string (inferred)
const explicit = identity<boolean>(true); // boolean (explicit)
```

## Inference from arguments

A type parameter is inferred only from positions where it appears. If it is not used in an argument, it defaults to `unknown`.

```ts
// BAD - TConfig never appears in the parameters, so it is unknown
const createComponent = <TConfig>(config: Record<string, string>) => {};

// GOOD - TConfig is the argument type
const createComponent = <TConfig extends Record<string, string>>(
  config: TConfig,
) => {
  return (variant: keyof TConfig, ...otherClasses: string[]): string => {
    return config[variant] + " " + otherClasses.join(" ");
  };
};

// TConfig inferred as { primary: string; secondary: string }
const getButtonClasses = createComponent({
  primary: "bg-blue-300",
  secondary: "bg-green-300",
});

getButtonClasses("primary", "px-4"); // OK
getButtonClasses("tertiary", "px-4"); // Error: "tertiary" not in keys
```

## Constraints with `extends`

Constrain a type parameter to the shape you actually use. Without a constraint, `T` has no members.

```ts
function getLength<T>(item: T): number {
  return item.length; // Error: Property 'length' does not exist on type 'T'
}

function getLength<T extends { length: number }>(item: T): number {
  return item.length;
}

getLength("hello"); // 5
getLength([1, 2, 3]); // 3
getLength(42); // Error: number has no length
```

Constraints also unlock utility types on the parameter:

```ts
type WrapFunction<TFunc extends (...args: any) => any> = (
  ...args: Parameters<TFunc>
) => ReturnType<TFunc>;
```

Only require what the body uses:

```ts
// BAD - over-constrained
function process<T extends { id: string; name: string; email: string }>(obj: T): void {}

// GOOD
function process<T extends { id: string }>(obj: T): void {}
```

A generic that does not preserve or relate any type is noise; `greet<T extends string>(name: T): string` should be `greet(name: string): string`.

## Default type parameters

```ts
type WrapFunction<
  TFunc extends (...args: any) => any,
  TAdditional = {},
> = (...args: Parameters<TFunc>) => Promise<Awaited<ReturnType<TFunc>> & TAdditional>;

type BasicWrapper = WrapFunction<typeof fetchUser>;
type ExtendedWrapper = WrapFunction<typeof fetchUser, { meta: string }>;
```

## Multiple type parameters

```ts
function map<TInput, TOutput>(
  items: TInput[],
  transform: (item: TInput) => TOutput,
): TOutput[] {
  return items.map(transform);
}

const numbers = map(["1", "2", "3"], (s) => parseInt(s));
// TInput: string, TOutput: number, result: number[]
```

## Generic classes

```ts
class Container<T> {
  constructor(private value: T) {}

  getValue(): T {
    return this.value;
  }

  map<U>(transform: (value: T) => U): Container<U> {
    return new Container(transform(this.value));
  }
}

const numContainer = new Container(42);
const strContainer = numContainer.map((n) => n.toString()); // Container<string>
```

## Deep inference

TypeScript widens literals when inferring objects and arrays: `["query", "page"]` becomes `string[]`, `"#0066cc"` becomes `string`. APIs that key off config literals (routers, themes, event maps) need the literals preserved.

```ts
const makeRouter = <TConfig>(config: TConfig) => ({ config });

const router = makeRouter({
  "/": {},
  "/search": { search: ["query", "page"] },
});
// TConfig["/search"]["search"] is string[], not ["query", "page"]
```

### `const` type parameters (TypeScript 5.0+)

Preferred. Built in, works with constraints, no caller action.

```ts
const makeRouter = <const TConfig extends BaseRouterConfig>(config: TConfig) => ({ config });

const router = makeRouter({
  "/": {},
  "/search": { search: ["query", "page"] },
});
// search is readonly ["query", "page"]
```

```ts
const createTheme = <const TTheme extends Record<string, string>>(theme: TTheme): TTheme => theme;

const theme = createTheme({ primary: "#0066cc", secondary: "#666666" });
// theme.primary is "#0066cc"
```

Preserved literals feed indexed-access and conditional types:

```ts
const makeApi = <const TConfig extends Record<string, { returns: string }>>(config: TConfig) => ({
  call: <TMethod extends keyof TConfig>(method: TMethod): TConfig[TMethod]["returns"] => {
    return "" as any;
  },
});

const api = makeApi({
  getUser: { returns: "User" },
  getPost: { returns: "Post" },
});

api.call("getUser"); // "User"
api.call("getPost"); // "Post"
```

### Caller-supplied `as const`

Works without changing the API, but callers must remember it and the result is `readonly` throughout.

```ts
const router = makeRouter({
  "/": {},
  "/search": { search: ["query", "page"] },
} as const);
// readonly "/search": { readonly search: readonly ["query", "page"] }

const config = { values: [1, 2, 3] } as const;
config.values.push(4); // Error: no 'push' on readonly [1, 2, 3]
```

### `F.Narrow` from ts-toolbelt (pre-5.0)

Wrap the parameter type; `F.Narrow` recursively narrows strings and numbers to literals, arrays to tuples, and object properties. The type parameter must still be constrained or inference has no base.

```ts
import { F } from "ts-toolbelt";

type BaseRouterConfig = Record<string, { search?: string[] }>;

type TupleToSearchParams<T extends string[]> = {
  [K in T[number]]?: string;
};

const makeRouter = <TConfig extends BaseRouterConfig>(config: F.Narrow<TConfig>) => ({
  config,
  goTo: <TRoute extends keyof TConfig>(
    route: TRoute,
    search?: TConfig[TRoute]["search"] extends string[]
      ? TupleToSearchParams<TConfig[TRoute]["search"]>
      : never,
  ) => {},
});

const router = makeRouter({
  "/": {},
  "/dashboard": { search: ["page", "perPage", "sort"] },
});

router.goTo("/dashboard", { page: "1", perPage: "10", sort: "name" });
router.goTo("/dashboard", { invalid: "value" }); // Error
```

Without the library, a reduced version:

```ts
type Narrow<T> = T extends Function
  ? T
  : T extends []
    ? []
    : T extends readonly [infer First, ...infer Rest]
      ? [Narrow<First>, ...Narrow<Rest>]
      : T extends object
        ? { [K in keyof T]: Narrow<T[K]> }
        : T;
```

| Technique | Pros | Cons |
|-----------|------|------|
| `const` type param | Built in, clean, works with constraints | TypeScript 5.0+ |
| `as const` | No API change | Caller must remember; readonly types |
| `F.Narrow` | Automatic on older TS | External dependency |
| Custom `Narrow` | No dependency | Misses edge cases |

Very deeply nested narrowed types slow the compiler; keep config shapes shallow.
