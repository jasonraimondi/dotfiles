# Conditional types and infer

Type-level if/else. `A extends B ? X : Y` resolves to `X` when `A` is assignable to `B`, otherwise `Y`.

```typescript
type IsString<T> = T extends string ? true : false;

type T1 = IsString<string>; // true
type T2 = IsString<number>; // false
type T3 = IsString<"hello">; // true (literal extends string)

type IsNullable<T> = null extends T ? true : false;
type N1 = IsNullable<string | null>; // true
type N2 = IsNullable<undefined>; // false (null !== undefined)
```

## Chaining

Nest in the false branch for multi-way dispatch. Recursion works; put base cases first.

```typescript
type TypeName<T> = T extends string
  ? "string"
  : T extends number
  ? "number"
  : T extends boolean
  ? "boolean"
  : T extends undefined
  ? "undefined"
  : T extends Function
  ? "function"
  : "object";

type DeepReadonly<T> = T extends Function
  ? T
  : T extends object
  ? { readonly [K in keyof T]: DeepReadonly<T[K]> }
  : T;
```

## Distribution over unions

When the checked type is a bare type parameter and the argument is a union, the conditional runs once per member and the results are unioned.

```typescript
type ToArray<T> = T extends any ? T[] : never;
type R = ToArray<string | number>; // string[] | number[], not (string | number)[]

type IsArray<T> = T extends any[] ? true : false;
type A = IsArray<string | number[]>; // boolean (true | false)
```

Wrap both sides in a tuple to test the whole union at once:

```typescript
type ToArrayNonDistributive<T> = [T] extends [any] ? T[] : never;
type R = ToArrayNonDistributive<string | number>; // (string | number)[]

type IsArrayWhole<T> = [T] extends [any[]] ? true : false;
type A = IsArrayWhole<string | number[]>; // false
```

## `never` handling

Returning `never` from a distributive branch removes that member from the union. This is how `Extract` and `Exclude` are implemented.

```typescript
type Extract<T, U> = T extends U ? T : never;
type Exclude<T, U> = T extends U ? never : T;

type Mixed = "a" | "b" | 1 | 2 | true;
type OnlyStrings = Extract<Mixed, string>; // "a" | "b"
```

`never` as the input to a distributive conditional produces `never` (zero members to distribute over). Use the tuple wrap if you need to detect it: `[T] extends [never]`.

Always give the false branch a deliberate value. `never` in a function parameter position means "not allowed"; `T` means passthrough; `undefined` means absent.

## Tuple shape checks

```typescript
type IsEmptyArray<T extends any[]> = T extends []
  ? true
  : T extends [any, ...any[]]
  ? false
  : boolean; // unknown-length arrays

type E1 = IsEmptyArray<[]>; // true
type E2 = IsEmptyArray<[1]>; // false
type E3 = IsEmptyArray<string[]>; // boolean

type HasFields<T extends { fields?: string[] }> =
  T["fields"] extends [string, ...string[]] ? true : false;
```

## Conditionals in parameter positions

Gate a parameter on a config type. `never` makes the argument unpassable.

```typescript
const makeRouter = <TConfig extends Record<string, { search?: string[] }>>(
  config: TConfig
) => ({
  goTo: <TRoute extends keyof TConfig>(
    route: TRoute,
    search?: TConfig[TRoute]["search"] extends string[]
      ? { [K in TConfig[TRoute]["search"][number]]?: string }
      : never
  ) => {},
});

const router = makeRouter({
  "/": {},
  "/search": { search: ["query", "page"] },
});

router.goTo("/"); // no search param allowed
router.goTo("/search", { query: "test", page: "1" });
```

## When a conditional is the wrong tool

A conditional that maps inputs to a fixed set of output shapes is usually a discriminated union in disguise:

```typescript
type Result =
  | { type: "string"; value: string }
  | { type: "number"; value: number };
```

## `infer`

`infer X` inside the `extends` clause binds `X` to whatever occupies that position when the pattern matches. It is only valid inside a conditional type's check.

```typescript
type ExtractType<T> = T extends SomePattern<infer U> ? U : never;
```

### Structural extraction

```typescript
type ArrayElement<T> = T extends (infer U)[] ? U : never;
type A1 = ArrayElement<(string | number)[]>; // string | number
type A2 = ArrayElement<string>; // never

type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;
type P1 = UnwrapPromise<Promise<string>>; // string
type P2 = UnwrapPromise<string>; // string (passthrough)

type GetData<T> = T extends { data: infer TData } ? TData : never;
type D1 = GetData<{ data: number[] }>; // number[]
type D2 = GetData<{ other: string }>; // never
```

Multiple captures and multi-pattern dispatch:

```typescript
type ExtractGeneric<T> = T extends Array<infer U>
  ? U
  : T extends Map<infer K, infer V>
  ? { key: K; value: V }
  : T extends Set<infer U>
  ? U
  : never;

type G1 = ExtractGeneric<Map<string, number>>; // { key: string; value: number }
```

### Functions and constructors

```typescript
type MyReturnType<T> = T extends (...args: any[]) => infer R ? R : never;
type MyParameters<T> = T extends (...args: infer P) => any ? P : never;
type FirstArg<T> = T extends (first: infer F, ...rest: any[]) => any ? F : never;
type ConstructorParams<T> = T extends new (...args: infer P) => any ? P : never;

type R = MyReturnType<() => string>; // string
type P = MyParameters<(a: string, b: number) => void>; // [a: string, b: number]
type F = FirstArg<(name: string, age: number) => void>; // string

class User {
  constructor(public name: string, public age: number) {}
}
type UserParams = ConstructorParams<typeof User>; // [string, number]

type EventHandler<T> = T extends (event: infer E) => void ? E : never;
interface Events {
  click: (event: MouseEvent) => void;
}
type ClickEvent = EventHandler<Events["click"]>; // MouseEvent
```

### Tuple positions

```typescript
type First<T> = T extends [infer F, ...any[]] ? F : never;
type Last<T> = T extends [...any[], infer L] ? L : never;

type TF = First<[1, 2, 3]>; // 1
type TL = Last<[1, 2, 3]>; // 3

type NonEmptyArray<T extends any[]> = T extends [infer First, ...infer Rest]
  ? [First, ...Rest]
  : never;
```

### Template literals

```typescript
type RemoveMaps<T> = T extends `maps:${infer Rest}` ? Rest : T;
type M1 = RemoveMaps<"maps:longitude">; // "longitude"
type M2 = RemoveMaps<"other">; // "other"

type Before<T> = T extends `${infer Prefix}:${string}` ? Prefix : T;
type After<T> = T extends `${string}:${infer Suffix}` ? Suffix : T;

type ParseKeyValue<T> = T extends `${infer Key}=${infer Value}`
  ? { key: Key; value: Value }
  : never;
type KV = ParseKeyValue<"name=John">; // { key: "name"; value: "John" }
```

Each `infer` in a template literal matches the shortest string that lets the remaining pattern match, except the last one, which takes the rest:

```typescript
type GetPath<T> = T extends `${infer Path}.json` ? Path : never;
type G = GetPath<"folder/file.name.json">; // "folder/file.name"
```

Recursive parsing:

```typescript
type ExtractParams<T extends string> =
  T extends `${string}:${infer Param}/${infer Rest}`
    ? Param | ExtractParams<`/${Rest}`>
    : T extends `${string}:${infer Param}`
    ? Param
    : never;

type Params = ExtractParams<"/users/:userId/posts/:postId">; // "userId" | "postId"
```

Combine with key remapping to transform object keys:

```typescript
type RemoveMapsPrefixFromObj<T> = {
  [K in keyof T as RemoveMaps<K>]: T[K];
};

interface ApiData {
  "maps:longitude": string;
  "maps:latitude": string;
  city: string;
}
type Cleaned = RemoveMapsPrefixFromObj<ApiData>;
// { longitude: string; latitude: string; city: string }
```

### Constrained infer

`infer X extends C` fails the match when the captured type does not satisfy `C` (TS 4.7+).

```typescript
type ExtractString<T> = T extends { value: infer V extends string } ? V : never;

type S1 = ExtractString<{ value: "hello" }>; // "hello"
type S2 = ExtractString<{ value: 123 }>; // never
```

### Recursive unwrapping

```typescript
type DeepAwaited<T> = T extends Promise<infer U> ? DeepAwaited<U> : T;
type DA = DeepAwaited<Promise<Promise<Promise<string>>>>; // string
```

### Distribution still applies

`infer` does not change distribution rules; a bare type parameter on the left still distributes.

```typescript
type ExtractArray<T> = T extends (infer U)[] ? U : never;
type X = ExtractArray<string[] | number[]>; // string | number
```
