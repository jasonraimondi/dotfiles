# Svelte templates

Rules for editing Svelte components rather than standalone HTML documents.

## Template safety

- Preserve Svelte syntax: `{#if}`, `{#each}`, `{:else}`, `{@html}`, `bind:`, `class:`, `style:`, event attributes, `<svelte:head>`.
- Do not replace components (capitalized tags) with native elements unless the task asks for it.
- Do not add `<!doctype html>`, `<html>`, `<head>`, or `<body>` inside component files. Document metadata goes through `<svelte:head>`.
- Treat compiler accessibility warnings as guardrails. Do not silence them with `svelte-ignore` casually.

## Heuristics

- Am I editing a document or a component? Would this break a directive, binding, or component boundary?
