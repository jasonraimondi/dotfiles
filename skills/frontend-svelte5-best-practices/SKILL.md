---
name: frontend-svelte5-best-practices
description: "Svelte 5 runes, snippets, SvelteKit patterns, and modern best practices. Use when creating, editing, reviewing, or refactoring .svelte components, .svelte.ts/.svelte.js modules, or SvelteKit applications. Triggers on: runes ($state, $derived, $effect, $props, $bindable, $inspect), snippets ({#snippet}, {@render}), event handling, SvelteKit data loading, form actions, Svelte 4→5 migration, TypeScript props, generic components, SSR state isolation, performance, or component testing."
license: MIT
metadata:
  author: ejirocodes
  version: '2.1.0'
---

# Svelte 5 Best Practices

## Workflow

Follow this sequence when working on Svelte 5 code:

1. **Check project version** — Inspect `package.json` for Svelte version. If < 5, consult [migration.md](references/migration.md) before writing any code.
2. **Read relevant references** — Before writing or modifying a component, read the reference file(s) matching your task from the table below.
3. **Write code** — Apply patterns from references and the quick patterns below.
4. **Validate** — Run the autofixer on modified components:
   ```bash
   npx @sveltejs/mcp svelte-autofixer ./src/lib/Component.svelte
   ```

## CLI Tools

```bash
npx @sveltejs/mcp list-sections                              # List doc sections
npx @sveltejs/mcp get-documentation "$state,$derived,$effect" # Fetch specific docs
npx @sveltejs/mcp svelte-autofixer ./path/Component.svelte    # Validate component (escape $ as \$)
```

## Reference Lookup

Read the matching file **before** writing code for that topic.

| Topic | When to Read | File |
|-------|-------------|------|
| **Runes** | $state, $derived, $effect, $props, $bindable, $inspect | [runes.md](references/runes.md) |
| **Snippets** | Replacing slots, {#snippet}, {@render} | [snippets.md](references/snippets.md) |
| **Events** | onclick handlers, callback props, context API | [events.md](references/events.md) |
| **TypeScript** | Props typing, generic components | [typescript.md](references/typescript.md) |
| **Migration** | Svelte 4→5, stores→runes, slots→snippets | [migration.md](references/migration.md) |
| **SvelteKit** | Load functions, form actions, SSR, page typing | [sveltekit.md](references/sveltekit.md) |
| **Performance** | Universal reactivity, avoiding over-reactivity, streaming | [performance.md](references/performance.md) |

## Essential Patterns

### Reactive State

```svelte
<script>
  let count = $state(0);            // Reactive state
  let doubled = $derived(count * 2); // Computed value
</script>
```

### Component Props

```svelte
<script>
  let { name, count = 0 } = $props();
  let { value = $bindable() } = $props(); // Two-way binding
</script>
```

### Snippets (replacing slots)

```svelte
<script>
  let { children, header } = $props();
</script>

{@render header?.()}
{@render children()}
```

### Event Handlers

```svelte
<!-- Svelte 5: use onclick, not on:click -->
<button onclick={() => count++}>Click</button>
```

### Callback Props (replacing createEventDispatcher)

```svelte
<script>
  let { onclick } = $props();
</script>

<button onclick={() => onclick?.({ data })}>Click</button>
```

## Common Mistakes

1. **`let` without `$state`** — Variables are not reactive without `$state()`
2. **`$effect` for derived values** — Use `$derived` instead
3. **`on:click` syntax** — Use `onclick` in Svelte 5
4. **`createEventDispatcher`** — Use callback props instead
5. **`<slot>`** — Use snippets with `{@render}`
6. **Missing `$bindable()`** — Required for `bind:` to work
7. **Module-level state in SSR** — Causes cross-request data leaks
8. **Sequential awaits in load** — Use `Promise.all` for parallel requests
9. **Mixing Svelte 4/5 patterns** — Check project version first; don't mix syntaxes
